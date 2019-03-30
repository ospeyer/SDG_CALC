#!/bin/bash
#cd SDG_CALC/INPUT
unzip ../INPUT/INPUT_shp.zip -d ../INPUT
#cd ../
#cd SOURCE
#pwd
/opt/conda/envs/nclenv/bin/ncl  CAMS_shapefile.ncl
rm ../INPUT/TR*
