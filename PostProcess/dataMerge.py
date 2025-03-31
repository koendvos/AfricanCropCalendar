# -*- coding: utf-8 -*-
"""
Created on Sat Feb 24 13:54:06 2024

@author: U8017882
"""


##### setup
####################################################################################################################
####################################################################################################################


### package imports
##########################################################
import os
import sys
from pathlib import Path
import tempfile
import gc
import getpass
import socket
import warnings
import copy
import pickle
import glob
import tarfile
import shutil

import itertools
from functools import reduce
import decimal

import datetime as dt
import time

import statsmodels.stats.api as sms

import numpy as np
import pandas as pd
import xarray as xr

import pyarrow as pa
import pyarrow.parquet as pq

import geopandas as gpd
from pyproj import CRS
import shapely

import matplotlib as mpl
import matplotlib.pyplot as plt
import seaborn as sns
from mpl_toolkits.axes_grid1 import make_axes_locatable



### path locations & environmental variables
##########################################################


### define project folder path 
githubRepo_path = Path(r'C:\Users\U8017882\OneDrive - USQ\Documents\01_projects\02_LSMS_cropSeasons\LSMS_multiplecropping')
    
# set working directory to project path
os.chdir(githubRepo_path)




##### load country datasets and metadata
####################################################################################################################
####################################################################################################################

# directory containing final datasets and metadata
outData_dir = os.path.join( githubRepo_path, 'out' )

# load datasets into dict
dataset_dct= {
    'ETH_all_pd': pd.read_csv( os.path.join( outData_dir, 'ETH_allWaves.csv') ),
    'MLI_all_pd': pd.read_csv( os.path.join( outData_dir, 'MLI_allWaves.csv') ),
    'MWI_all_pd': pd.read_csv( os.path.join( outData_dir, 'MWI_allWaves.csv') ),
    'UGA_many_pd': pd.read_csv( os.path.join( outData_dir, 'UGA_allWaves.csv') ),
    'UGA_2011_pd': pd.read_csv( os.path.join( outData_dir, 'uganda11-12.csv') ),
    'UGA_2013_pd': pd.read_csv( os.path.join( outData_dir, 'uganda13-14.csv') ),
    'NIG_2015_pd': pd.read_csv( os.path.join( outData_dir, 'Nigeria_GHS_W3_results.csv') ),
    'NIG_2018_pd': pd.read_csv( os.path.join( outData_dir, 'Nigeria_GHS_W4_results.csv') ),
    'NER_2011_pd': pd.read_csv( os.path.join( outData_dir, 'Niger11-12.csv') ),
    'NER_2014_pd': pd.read_csv( os.path.join( outData_dir, 'NER_2014-15.csv') ),
    }

## dataset template
dataset_template_pd = pd.read_csv( os.path.join(githubRepo_path, r'documentation\dataset_template\dataset_template.csv') )

## target columns list
targetCols_dataset_lst = dataset_template_pd.columns.to_list()





# load metadata into dict
metadata_dct= {
    'ETH_all_pd': pd.read_csv( os.path.join( outData_dir, 'ETH_allWaves_metadata.csv') ),
    'MLI_2014_pd': pd.read_csv( os.path.join( outData_dir, 'MLI_2014-15_metadata.csv'), sep = ';', decimal=",", encoding='ISO-8859-1' ),
    'MLI_2017_pd': pd.read_csv( os.path.join( outData_dir, 'MLI_2017-18_metadata.csv'), sep = ';', decimal=",", encoding='ISO-8859-1' ),
    'MWI_all_pd': pd.read_csv( os.path.join( outData_dir, 'MWI_allWaves_metadata.csv') ),
    'UGA_2011_pd': pd.read_csv( os.path.join( outData_dir, 'uganda11-12_meta.csv') ),
    'UGA_2013_pd': pd.read_csv( os.path.join( outData_dir, 'uganda13-14_meta.csv') ),
    'UGA_many_pd': pd.read_csv( os.path.join( outData_dir, 'UGA_allWaves_metadata.csv') ),
    'NIG_2015_pd': pd.read_csv( os.path.join( outData_dir, 'NGA_2016_metadata.csv') ),
    'NIG_2018_pd': pd.read_csv( os.path.join( outData_dir, 'NGA_2018_metadata.csv') ),
    'NER_2011_pd': pd.read_csv( os.path.join( outData_dir, 'Niger11-12_meta.csv') ),
    'NER_2014_pd': pd.read_csv( os.path.join( outData_dir, 'NER_2014-15_metadata.csv'), sep = ';', decimal=",", encoding='ISO-8859-1' ),
    }




## metadata template
metadata_template_pd = pd.read_csv( os.path.join(githubRepo_path, r'documentation\metadata_template\metadata_template.csv') )

## target columns list
targetCols_metadata_lst = metadata_template_pd.columns.to_list()



##### inspect datasets & metadata
####################################################################################################################
####################################################################################################################


### inspect datasets
##########################################################

## dictionary with descriptive information
datasetsInspect_dct = {}

# add keys to dictionary
for key in dataset_dct.keys():
    datasetsInspect_dct[ key[0:-3] ] = {}


### inspect missing columns

#loop over datasets
for df_string, df in dataset_dct.items():
    
    # list of missing columns
    missingCols_lst_tmp = []
    # list of additional, non-target columns
    nontargetCols_dataset_lst_tmp = []
    
    # loop over target columns
    for targetCol in targetCols_dataset_lst:
        
        # check if dataset contains target column
        if targetCol not in df.columns:
            # if missing: record column-name as missing
            missingCols_lst_tmp.append(targetCol)
            
    # loop over dataset columns
    for datasetCol in df.columns.to_list():
        
        # check if dataset-column is part of target columns
        if datasetCol not in targetCols_dataset_lst:
            nontargetCols_dataset_lst_tmp.append(datasetCol)
            
    # store list of missing columns to descriptive dictionary
    datasetsInspect_dct[df_string[0:-3]]['missingCols_lst'] = missingCols_lst_tmp
    # store list of additional, non-target columns to descriptive dictionary
    datasetsInspect_dct[df_string[0:-3]]['nontargetCols_dataset_lst'] = nontargetCols_dataset_lst_tmp





### inspect metadata
##########################################################

## dictionary with descriptive information
metadataInspect_dct = {}

# add keys to dictionary
for key in metadata_dct.keys():
    metadataInspect_dct[ key[0:-3] ] = {}


### inspect missing columns

#loop over metadata-datasets
for df_string, df in metadata_dct.items():
    
    # list of missing columns
    missingCols_lst_tmp = []
    # list of additional, non-target columns
    nontargetCols_metadata_lst_tmp = []
    
    # loop over target columns
    for targetCol in targetCols_metadata_lst:
        
        # check if metadata contains target column
        if targetCol not in df.columns:
            # if missing: record column-name as missing
            missingCols_lst_tmp.append(targetCol)
            
    # loop over metadata columns
    for metadataCol in df.columns.to_list():
        
        # check if metadata-column is part of target columns
        if metadataCol not in targetCols_metadata_lst:
            nontargetCols_metadata_lst_tmp.append(metadataCol)
            
    # store list of missing columns to descriptive dictionary
    metadataInspect_dct[df_string[0:-3]]['missingCols_lst'] = missingCols_lst_tmp
    # store list of additional, non-target columns to descriptive dictionary
    metadataInspect_dct[df_string[0:-3]]['nontargetCols_dataset_lst'] = nontargetCols_metadata_lst_tmp








##### harmonize datasets & metadata
####################################################################################################################
####################################################################################################################


### harmonize datasets
##########################################################



## Niger (2011)
##########

# rename variables to correspond to template
dataset_dct['NER_2011_pd'].rename( {
    'long': 'lon',
    'harvesting_month': 'harvest_month',
    'harvesting_year': 'harvest_year',
    'source': 'dataset_name',
    }, axis = 1, inplace = True)


# overwrite GPS_level value: using harmonised naming convention
dataset_dct['NER_2011_pd']['GPS_level'].replace(
    to_replace=['Grappe'],
    value=3,
    inplace=True
)

# set variables genuinely missing in original dataset to NaN
dataset_dct['NER_2011_pd']['adm3'] = np.nan
dataset_dct['NER_2011_pd']['adm4'] = np.nan
dataset_dct['NER_2011_pd']['harvest_month_begin'] = np.nan
dataset_dct['NER_2011_pd']['harvest_year_begin'] = np.nan
dataset_dct['NER_2011_pd']['harvest_month_end'] = np.nan
dataset_dct['NER_2011_pd']['harvest_year_end'] = np.nan

# drop redundant variables
dataset_dct['NER_2011_pd'].drop('grappe', axis = 1, inplace = True)
dataset_dct['NER_2011_pd'].drop('plotNbr', axis = 1, inplace = True)
dataset_dct['NER_2011_pd'].drop('cropID', axis = 1, inplace = True)

# preliminarily, set outsanding variables to NaN
dataset_dct['NER_2011_pd']['season'] = np.nan



## Nigeria (2015)
##########

# drop redundant variables
dataset_dct['NIG_2015_pd'].drop('wave', axis = 1, inplace = True)
dataset_dct['NIG_2015_pd'].drop('dm_gender', axis = 1, inplace = True)
dataset_dct['NIG_2015_pd'].drop('gps_meas', axis = 1, inplace = True)

# set variables genuinely missing in original dataset to NaN
dataset_dct['NIG_2015_pd']['fieldID'] = np.nan

# set redundant variables to NaN
dataset_dct['NIG_2015_pd']['harvest_year'] = np.nan
dataset_dct['NIG_2015_pd']['harvest_month'] = np.nan



## Nigeria (2018)
##########

# rename variables to correspond to template
dataset_dct['NIG_2018_pd'].rename( {
    'longitude': 'lon',
    'latitude': 'lat',
    }, axis = 1, inplace = True)

# drop redundant variables
dataset_dct['NIG_2018_pd'].drop('wave', axis = 1, inplace = True)
dataset_dct['NIG_2018_pd'].drop('dm_gender', axis = 1, inplace = True)
dataset_dct['NIG_2018_pd'].drop('gps_meas', axis = 1, inplace = True)

# set variables genuinely missing in original dataset to NaN
dataset_dct['NIG_2018_pd']['fieldID'] = np.nan

# set redundant variables to NaN
dataset_dct['NIG_2018_pd']['harvest_year'] = np.nan
dataset_dct['NIG_2018_pd']['harvest_month'] = np.nan





## Uganda (2011)
##########

# rename variables to correspond to template
dataset_dct['UGA_2011_pd'].rename( {
    'longitude': 'lon',
    'latitude': 'lat',
    'source': 'dataset_name',
    }, axis = 1, inplace = True)


# set variables genuinely missing in original dataset to NaN
dataset_dct['UGA_2011_pd']['fieldID'] = np.nan




## Uganda (2013)
##########

# rename variables to correspond to template
dataset_dct['UGA_2013_pd'].rename( {
    'longitude': 'lon',
    'latitude': 'lat',
    'source': 'dataset_name',
    }, axis = 1, inplace = True)


# set variables genuinely missing in original dataset to NaN
dataset_dct['UGA_2013_pd']['fieldID'] = np.nan

# correct variable name of fully missing variable to correspond to template
dataset_dct['UGA_2013_pd'].rename( {
    'plot_area_measured': 'plot_area_measured_ha',
    }, axis = 1, inplace = True)





### harmonize metadata
##########################################################


## Niger (2011)
##########

# complete missing variable-name value (copying value from unnamed column that otherwise only contains duplicates)
metadata_dct['NER_2011_pd'].loc[ metadata_dct['NER_2011_pd']['varName_source'] == 'as02bq03',  'varName_harmonized' ] = 'plotNbr'

# drop redundant variables: unnamed columns
for col_tmp in metadata_dct['NER_2011_pd'].columns:
    if 'Unnamed' in col_tmp:
        metadata_dct['NER_2011_pd'].drop(col_tmp, axis = 1, inplace = True)

# overwrite dataset_name
metadata_dct['NER_2011_pd']['dataset_name'] = "NER_2011_ECVMA_v01_M"

# overwrite dataset_doi
metadata_dct['NER_2011_pd']['dataset_doi'] = "https://doi.org/10.48529/bp16-s524"

# rename variables to correspond to template
metadata_dct['NER_2011_pd']['varName_harmonized'].replace(
    {
     'latitude': 'lat',
     'longitude': 'lon',
     },
    inplace=True
)

# drop redundant variable-values
metadata_dct['NER_2011_pd'].drop( 
    metadata_dct['NER_2011_pd'][metadata_dct['NER_2011_pd']['varName_harmonized'] == 'plotNbr'].index, 
    inplace=True)



## Nigeria (2015)
##########

# set missing statistics-variable to NaN
metadata_dct['NIG_2015_pd']['pctMissing_harmonized'] = np.NaN
metadata_dct['NIG_2015_pd']['pctMissing_source'] = np.NaN


## Nigeria (2018)
##########

# set missing statistics-variable to NaN
metadata_dct['NIG_2018_pd']['pctMissing_harmonized'] = np.NaN
metadata_dct['NIG_2018_pd']['pctMissing_source'] = np.NaN






##### merge datasets & metadata
####################################################################################################################
####################################################################################################################





### merge datasets
##########################################################

# load all individual dataframes into single dataframe
allData_pd = pd.concat(dataset_dct.values(), axis=0, ignore_index=True)

# drop rows that are NaN across all columns
allData_pd.dropna(axis = 0, how = 'all', inplace = True)

# save to disk
allData_pd.to_csv( os.path.join( githubRepo_path, 'PostProcess', f'data_merged.csv'), index=False )
# allData_pd.to_csv( os.path.join( githubRepo_path, 'PostProcess', f'data_merged_{dt.datetime.today().strftime('%Y%m%d')}.csv') )



### merge metadata
##########################################################

# load all individual metadata-files into single dataframe
allMetadata_pd = pd.concat(metadata_dct.values(), axis=0, ignore_index=True)

# drop rows that are NaN across all columns
allMetadata_pd.dropna(axis = 0, how = 'all', inplace = True)

# save to disk
allMetadata_pd.to_csv( os.path.join( githubRepo_path, 'PostProcess', f'metadata_merged.csv'), index=False )
# allMetadata_pd.to_csv( os.path.join( githubRepo_path, 'PostProcess', f'metadata_merged_{dt.datetime.today().strftime('%Y%m%d')}.csv') )






##### explore datasets & metadata
####################################################################################################################
####################################################################################################################

## overall descriptive statistics
##########

# dataset of descriptive stats
dataDescription_dct = {}

# loop over datasets
for dataset_name in allData_pd['dataset_name'].drop_duplicates():
    
    # subset to single dataset
    df_tmp = allData_pd.loc[allData_pd['dataset_name'] == dataset_name]
            
    ## generate df of descriptive stats
    stats_pd = df_tmp.describe(include = 'all')
    stats_pd.loc['dtype'] = df_tmp.dtypes
    stats_pd.loc['Obs'] = len(df_tmp)
    stats_pd.loc['Perc_NaN'] = 100* df_tmp.isna().sum() / len(df_tmp)
    # stats_pd.loc['Frac null'] = df_tmp.isnull().mean()
            
    ## append descriptive stats to dct
    dataDescription_dct[dataset_name] = stats_pd




## review: crop_area_share
##########

# delete storage container (if available from previous iteration)
try:
    cropAreaShare_pd
except NameError:
    pass
else:
    del cropAreaShare_pd

# loop over datasets
for dataset_name in allData_pd['dataset_name'].drop_duplicates():
    
    # subset to single dataset
    df_tmp = allData_pd.loc[allData_pd['dataset_name'] == dataset_name]
    
    # get descriptive stats for crop_area_share
    stats_srs = df_tmp['crop_area_share'].describe(include = 'all')
    stats_srs.loc['dtype'] = df_tmp['crop_area_share'].dtypes
    stats_srs.loc['Obs'] = len(df_tmp['crop_area_share'])
    stats_srs.loc['Perc_NaN'] = 100* df_tmp['crop_area_share'].isna().sum() / len(df_tmp['crop_area_share'])

    # rename series
    stats_srs.rename(dataset_name, inplace=True)

    ## append descriptive stats to storage
    try:
        cropAreaShare_pd
    except NameError:
        # convert series to dataframe
        cropAreaShare_pd = stats_srs.to_frame()
        # cropAreaShare_pd = stats_srs.to_frame().transpose()
    else:
        # add series to dataframe
        cropAreaShare_pd[dataset_name] = stats_srs




## review: season
##########

# delete storage container (if available from previous iteration)
try:
    season_pd
except NameError:
    pass
else:
    del season_pd

# loop over datasets
for dataset_name in allData_pd['dataset_name'].drop_duplicates():
    
    # subset to single dataset
    df_tmp = allData_pd.loc[allData_pd['dataset_name'] == dataset_name]
    
    # get descriptive stats for season
    stats_srs = df_tmp['season'].describe(include = 'all')
    stats_srs.loc['dtype'] = df_tmp['season'].dtypes
    stats_srs.loc['Obs'] = len(df_tmp['season'])
    stats_srs.loc['Perc_NaN'] = 100* df_tmp['season'].isna().sum() / len(df_tmp['season'])

    # rename series
    stats_srs.rename(dataset_name, inplace=True)

    ## append descriptive stats to storage
    try:
        season_pd
    except NameError:
        # convert series to dataframe
        season_pd = stats_srs.to_frame()
    else:
        # add series to dataframe
        season_pd[dataset_name] = stats_srs


## review: harvest_month_begin
##########

# delete storage container (if available from previous iteration)
try:
    harvestMonthBegin_pd
except NameError:
    pass
else:
    del harvestMonthBegin_pd

# loop over datasets
for dataset_name in allData_pd['dataset_name'].drop_duplicates():
    
    # subset to single dataset
    df_tmp = allData_pd.loc[allData_pd['dataset_name'] == dataset_name]
    
    # get descriptive stats for harvest_month_begin
    stats_srs = df_tmp['harvest_month_begin'].describe(include = 'all')
    stats_srs.loc['dtype'] = df_tmp['harvest_month_begin'].dtypes
    stats_srs.loc['Obs'] = len(df_tmp['harvest_month_begin'])
    stats_srs.loc['Perc_NaN'] = 100* df_tmp['harvest_month_begin'].isna().sum() / len(df_tmp['harvest_month_begin'])

    # rename series
    stats_srs.rename(dataset_name, inplace=True)

    ## append descriptive stats to storage
    try:
        harvestMonthBegin_pd
    except NameError:
        # convert series to dataframe
        harvestMonthBegin_pd = stats_srs.to_frame()
    else:
        # add series to dataframe
        harvestMonthBegin_pd[dataset_name] = stats_srs



## review: planting_month
##########

# delete storage container (if available from previous iteration)
try:
    planting_month_pd
except NameError:
    pass
else:
    del planting_month_pd

# loop over datasets
for dataset_name in allData_pd['dataset_name'].drop_duplicates():
    
    # subset to single dataset
    df_tmp = allData_pd.loc[allData_pd['dataset_name'] == dataset_name]
    
    # get descriptive stats for planting_month
    stats_srs = df_tmp['planting_month'].describe(include = 'all')
    stats_srs.loc['dtype'] = df_tmp['planting_month'].dtypes
    stats_srs.loc['Obs'] = len(df_tmp['planting_month'])
    stats_srs.loc['Perc_NaN'] = 100* df_tmp['planting_month'].isna().sum() / len(df_tmp['planting_month'])

    # rename series
    stats_srs.rename(dataset_name, inplace=True)

    ## append descriptive stats to storage
    try:
        planting_month_pd
    except NameError:
        # convert series to dataframe
        planting_month_pd = stats_srs.to_frame()
    else:
        # add series to dataframe
        planting_month_pd[dataset_name] = stats_srs




## review: availability of growing period dates per dataset
##########

# dictionary of data availability on growing-period dates
growPeriodDates_dct = {}

# loop over descriptive-summary by dataframe
for dataset_name, dataDescr_pd in dataDescription_dct.items():
    
    growPeriodDescr_dct = {
        'planting_month_pNaN': dataDescr_pd.loc['Perc_NaN', 'planting_month'],
        'planting_year_pNaN': dataDescr_pd.loc['Perc_NaN', 'planting_year'],
        'harvest_month_begin_pNaN': dataDescr_pd.loc['Perc_NaN', 'harvest_month_begin'],
        'harvest_month_end_pNaN': dataDescr_pd.loc['Perc_NaN', 'harvest_month_end'],
        'harvest_month_pNaN': dataDescr_pd.loc['Perc_NaN', 'harvest_month'],
        'harvest_year_pNaN': dataDescr_pd.loc['Perc_NaN', 'harvest_year'],
        'harvest_year_begin_pNaN': dataDescr_pd.loc['Perc_NaN', 'harvest_year_begin'],
        'harvest_year_end_pNaN': dataDescr_pd.loc['Perc_NaN', 'harvest_year_end'],
        }
    
    # append to storage dct
    growPeriodDates_dct[dataset_name] = growPeriodDescr_dct


# convert dct to pandas
growPeriodDates_pd = pd.DataFrame.from_dict(growPeriodDates_dct)



