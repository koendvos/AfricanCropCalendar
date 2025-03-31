#!/bin/bash

# initializing bash to to use conda
conda init bash

# view the channel priority used by conda
conda config --describe channel_priority

# add conda-forge to the top of the channel configuration list
conda config --add channels conda-forge

# view all installed channels and the order of priority
conda config --get channels

#######################################################################
echo Generate a python environment with conda
#######################################################################

# option 1: generate an environment with conda by defining a name of the environment (this environment is saved in the conda-folder under C:\Users\uwegr\AppData\Local\Continuum\anaconda3\envs or /home/ugrewer/anaconda3/envs)
conda create -n growPeriod python numpy pandas xarray dask scipy statsmodels netcdf4 h5py h5netcdf matplotlib basemap gdal rasterio shapely pyproj pyogrio fiona geojson pysal geopandas geoplot spyder cdsapi fuzzywuzzy openpyxl rioxarray fastparquet pyarrow mechanicalsoup filelock python-docx

# view existing environments in conda
conda info --envs

# View list of packages and versions installed in indicated environment
conda list -n growPeriod

# Exporting the environment.yml file (when installing on other operating systems: use noDependencies-environment, noBuilds-environment, or txt-file)
conda env export -n growPeriod > condaEnv/pyEnv_growPeriod_withBuilds.yml
conda env export --no-builds -n growPeriod > condaEnv/pyEnv_growPeriod_noBuilds.yml
conda env export --from-history -n growPeriod > condaEnv/pyEnv_growPeriod_noDependencies.yml # best option for reproducible environments across different operating systems

# export a list of package specifications as a file in the current working directory
conda list --explicit > condaEnv/pyEnv_growPeriod_specFile.txt
