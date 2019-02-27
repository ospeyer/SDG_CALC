#!/bin/bash
cd SDG_CALC/INPUT
unzip INPUT_shp.zip
cd ../SOURCE
/opt/conda/envs/nclenv/bin/ncl  CAMS_shapefile.ncl

