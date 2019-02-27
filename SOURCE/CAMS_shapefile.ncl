;================================================;
; horizontal contour plot of the CAMS annual raeanalysis product and a Shapefile average
;================================================;

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "./shapefile_utils.ncl"

; ================================================;

begin

;=================================================;
; choose wks
;=================================================;

AVERAGE = 1
NCGM    = 0
X11     = 0
PS      = 1

;=================================================;
; Open shapefile and read lat/lon values.
;=================================================;
;Material from https://www.ncl.ucar.edu/Applications/Scripts/shapefiles_9.ncl

FUA ="ATHENS";FIRENZE, ATHENS, INSTANBUL, IZMIR
YEAR ="2016";2014, 2015,2016,2017 (Interim) available

if (FUA.eq."FIRENZE") then
	POPULATION = 760000 ;http://www.oecd.org/cfe/regional-policy/Italy.pdf
else if (FUA.eq."ATHENS")
	POPULATION = 3610000 ;http://www.oecd.org/cfe/regional-policy/Greece.pdf
else if (FUA.eq."INSTANBUL")
	POPULATION = 15067724 ;https://en.wikipedia.org/wiki/Istanbul
else if (FUA.eq."IZMIR")
	POPULATION = 4279677 ;https://en.wikipedia.org/wiki/%C4%B0zmir
end if
end if
end if
end if

ShPATH ="/work/pr001/eathana/orestis/KIT/KIT/COSMO-ART/COSMO_output/CAMS_SDG/"
print(ShPATH)
;fils2= systemfunc("ls /work/pr001/eathana/orestis/KIT/KIT/COSMO-ART/COSMO_output/CAMS_SDG/Boundary2012_EL001L1_ATHINA.shp")
;fils2= systemfunc("ls " + ShPATH + "/" +FUA+"/"+ "*.shp") ;Add whatever shapefile you find in the folder
fils2= systemfunc("ls ../SDG_CALC/INPUT/"+"*.shp") ;Add whatever shapefile you find in the folder
f       = addfile(fils2, "r")
shp_lon = tofloat( f->x )
shp_lat = tofloat( f->y )
nshp    = dimsizes(shp_lon)

;---Get Max & Min lat/lon for the shape file 

min_shp_lat = min(shp_lat) 
max_shp_lat = max(shp_lat)
min_shp_lon = min(shp_lon)
max_shp_lon = max(shp_lon)

;sname = fils2
sname = fils2
print(sname)
print_shapefile_info(sname)
plot_shapefile(sname)     ;To get a second image with the shapefile only
print ("Copernicus FUA shapefile link:https://land.copernicus.eu/local/urban-atlas/urban-atlas-2012")
;=================================================;
; open data file
;=================================================;
;COPERNICUS Atmosphere Monitoring Service
;http://www.regional.atmosphere.copernicus.eu/index.php?category=data_access&subensemble=reanalysis_products

;PATH = "/work/pr001/eathana/orestis/KIT/KIT/COSMO-ART/COSMO_output/CAMS_SDG"
;fils1= systemfunc("ls $PATH$+"/ENSa.2016.PM25.avg.nc")
;fils1= systemfunc("ls /work/pr001/eathana/orestis/KIT/KIT/COSMO-ART/COSMO_output/CAMS_SDG/ENSa.2016.PM25.avg.nc")
;fils1= systemfunc("ls /work/pr001/eathana/orestis/KIT/KIT/COSMO-ART/COSMO_output/CAMS_SDG/"+"ENSa."+YEAR+"*.nc")
;fils1= systemfunc("ls " + ShPATH +"ENSa."+YEAR+"*.nc")
fils1= systemfunc("ls ../SDG_CALC/INPUT/" + "*.nc")
f1  = addfiles(fils1,"r")


;================================================;
; read in data
;================================================;
PRM = "PM25"
pm25x = f1[:]->$PRM$(:,:,:)
;pm25 = f1[:]->$PRM$(0:ndata,lvl:39,{nbeglat:nendlat},{nbeglon:nendlon}) ;
pm25 = dim_avg_n_Wrap(pm25x,0)
printVarSummary (pm25)
printMinMax (pm25, True)
SCL1 = 5;0  ; minimum value
SCL2 = 25;40 ;maximum value
SCL3 = 1  ;stride

;================================================;
; Keep only values that fall inside the shapefile
;================================================;
pm25x_shp = f1[:]->$PRM$(:,{min_shp_lat:max_shp_lat},{min_shp_lon:max_shp_lon})
pm25_shp = dim_avg_n_Wrap(pm25x_shp,0)
printVarSummary (pm25_shp)
printMinMax (pm25_shp, True)
pm25_shp@_FillValue = -999 ; Assign a missing value
;SO FAR SO GOOD

;Create an empty array, with the largest size possible, fill with empty values,
;then fill with shapefile area values if any

dimp    = dimsizes(pm25_shp)
nlat    = dimp(0)
mlon    = dimp(1)

;---Create an array and initialize to _FillValue
pmask   = new(dimsizes(pm25_shp), typeof(pm25_shp), pm25_shp@_FillValue)  
copy_VarCoords(pm25_shp,pmask)

;---Keep only data within the polygon
;   Use NCL array syntax (:) to propagate to all times

  do nl=0,nlat-1
    do ml=0,mlon-1
      if(gc_inout(pm25_shp&lat(nl),pm25_shp&lon(ml),shp_lat,shp_lon)) then ;gc_inout function, true or false
         pmask(nl,ml) = pm25_shp(nl,ml)   
      end if
    end do
  end do

printVarSummary (pmask)
printMinMax (pmask, True)

N = num(.not.ismissing(pmask))
print ("The non-missing values are: "+N); This gives you the model's gridpoints within the shapefile
;SO far, we have a brand new array that is only filled with model gri-point values that fall within the shapefile

;===============================================;
;Do calculations in the new array
;===============================================;

legend_value = avg(pmask)  ;Simply get the average of your array
printVarSummary (legend_value)
printMinMax (legend_value, True)
legend_value = decimalPlaces (legend_value ,2, True)
;===============================================;
; plot standard stuff
;===============================================;
filename = "../OUTPUT/CAMS.SDG_"+FUA+"."+YEAR
;wks = gsn_open_wks("png","cams_contour")
wks = gsn_open_wks("png",filename)

;===============================================;
; Define Colormap
;===============================================;

gsn_define_colormap(wks,"gui_default")
;gsn_define_colormap(wks,"temp_19lev")
;gsn_define_colormap(wks,"posneg_2")

;================================================;
; Set some resources that will apply to the base
; contour/map plot
;================================================;

res                       = True
;res@gsnFrame              = True
res@gsnDraw               = False
res@gsnFrame              = False
;res@mpFillDrawOrder        = "PreDraw"

res@mpDataBaseVersion     = "HighRes"
res@gsnMaximize  = True     ; maximize plot in frame
res@cnFillOn     = True     ; turn on contour fill
res@cnLinesOn    = False    ; turn off contour fill
;res@tiMainString = "CAMS PM2.5 2016 reanalysis"
res@tiMainString = "CAMS PM2.5 "+YEAR+ " reanalysis"+", SDG Indicator"
;res@gsnLeftString   = "SDG 11.6.2, FUA of Athens = "+legend_value+" ug/m3"
res@gsnLeftString   = "11.6.2, FUA of "+ FUA +"="+legend_value+" ug/m3"
res@gsnRightString  = "Pop:"+POPULATION

res@mpProjection = "CylindricalEquidistant" ;"LambertConformal" ;Orthographic ;Internet says Use either Lambert Conformal Conic or Orthographic for Europe.
res@mpOutlineBoundarySets = "National"
res@mpLimitMode            = "LatLon"
res@mpMinLatF              = min_shp_lat-0.5 ;30.0                ; map area
res@mpMaxLatF              = max_shp_lat+0.5 ;70.0                ; latitudes
res@mpMinLonF              = min_shp_lon-0.5 ;-15.0 ;-25.0              ; and
res@mpMaxLonF              = max_shp_lon+0.5 ;45.0               ; longitudes
res@gsnAddCyclic = False

res@lbLabelAngleF         = 45                                             ; angle labels
res@cnLevelSelectionMode  = "ManualLevels"                             ; set manual contour levels
res@cnMinLevelValF        =  SCL1
res@cnMaxLevelValF        =  SCL2
res@cnLevelSpacingF       =  SCL3
res@cnLabelBarEndStyle    =  "ExcludeOuterBoxes"

res@pmTickMarkDisplayMode = "Always"
res@cnFillPalette = "gui_default"

;=================================================;
; Scaling
;=================================================;

res@vpWidthF  = 0.6                    ; change the aspect ratio
res@vpHeightF = 0.6
res@vpXF      = .1                     ; location of where plot starts
;res@vpYF      = 0.85

;=================================================;
; Plotting
;=================================================;

plot = gsn_csm_contour_map(wks,pm25,res)

;=================================================;
; Legend resources 
;=================================================;

;lgres                    = True
;lgres@lgLineColors       = (/"black","blue"/)    ; colors for legend lines
;lgres@vpWidthF           = 0.2                   ; width of legend (NDC)
;lgres@vpHeightF          = 0.1                   ; height of legend (NDC)
;lgres@lgPerimOn          = False ;True                 ; turn off perimeter
;lgres@lgDashIndexes      = (/0,12/)              ; dash indexes
;lgres@lgLineLabelStrings = (/"",""/)             ; no labels in lines
;lgres@lgBoxLineDashSegLenF   = 0.0001;       False            ; 
;**************************************************************
; Draw the legend, indicating the number of items, a label for each
; item, and the X, Y position of the legend in NDC coordinates.
;**************************************************************
;gsn_legend_ndc(wks,2,(/"gridpoints= "+N,"11.6.2 ="+legend_value/),0.4,0.15,lgres)
;gsn_legend_ndc(wks,2,(/"gridpoints= "+N,"11.6.2 for Athens ="+legend_value/),0.005,0.235,lgres)

draw(plot)
frame(wks)                                        ; finally advance frame

delete (pm25x)
delete (pm25)


end
