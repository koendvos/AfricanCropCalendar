#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Jul 14 22:52:05 2023

@author: ugrewer

Harmonize dataframe into final harmonized data-farmat as by formatting requirements.

"""


### package imports
##########################################################
import os
import socket
import sys
from pathlib import Path

import numpy as np
import pandas as pd

import datetime


### setup
##########################################################

### access project folder path (from environmental variable)
project_path = os.environ['growPeriodMWI']


# # add project directory to system path (note: system path expects only strings to be added - not pathlib_objects)
# if str(project_path) not in sys.path:
#     sys.path.append( str(project_path) )

# set working directory to project path
os.chdir(project_path)

# import major path locations
from scripts.defPaths import *



### load ingested panel-df
####################################################################################################################
####################################################################################################################
panel_pd = pd.read_csv( Path( str(project_path), 'scripts', 'LSMS_MWI_ingested', 'MWI_panel_cleaned.csv') )

# get list of column-names
colNames_lst = panel_pd.columns.to_list()



### harmonize variables
####################################################################################################################
####################################################################################################################

## add country
panel_pd['country'] = 'Malawi'


## rename region to ADM1
panel_pd.rename({'region': 'adm1'}, axis=1, inplace=True)

## rename district to ADM2
panel_pd.rename({'district': 'adm2'}, axis=1, inplace=True)

# inspect adm1 and adm2
panel_pd['adm1'].value_counts().sort_values()
panel_pd['adm2'].value_counts().sort_values()
list( panel_pd['adm1'].drop_duplicates().sort_values() )
list( panel_pd['adm2'].drop_duplicates().sort_values() )


# helper dicionary: identify ADM1 where missing (i.e., all of 2010 wave)
adm2_to_adm1 = {
    # Northern Region
    "chitipa": "northern",
    "karonga": "northern",
    "likoma": "northern",
    "mzimba": "northern",
    "mzuzu city": "northern",
    "nkhata bay": "northern",
    "rumphi": "northern",

    # Central Region
    "dedza": "central",
    "dowa": "central",
    "kasungu": "central",
    "lilongwe": "central",
    "lilongwe city": "central",
    "mchinji": "central",
    "nkhotakota": "central",
    "ntcheu": "central",
    "ntchisi": "central",
    "salima": "central",

    # Southern Region
    "balaka": "southern",
    "blantyre": "southern",
    "blantyre city": "southern",
    "chikwawa": "southern",
    "chiradzulu": "southern",
    "machinga": "southern",
    "mangochi": "southern",
    "mulanje": "southern",
    "mwanza": "southern",
    "neno": "southern",
    "nsanje": "southern",
    "phalombe": "southern",
    "thyolo": "southern",
    "zomba": "southern",
    "zomba city": "southern",
}

# assign imputed adm1-value
panel_pd['adm1'] = panel_pd['adm1'].fillna(
    panel_pd['adm2'].map(adm2_to_adm1)
)



# ## identify ADM1 where missing (i.e., all of 2010 wave)
# def imputeADM1(row):
#     ''' Impute ADM1 from ADM2 whenever possible - as adm1 is not reported for all observations in the 2010 wave.'''
    
#     # if adm1 is recorded: keep current value
#     if pd.notnull(row['adm1']):
#         print('Original:', row['adm1'])
#         return row['adm1']
    
#     # if both adm1 & adm2 are missing: return missing
#     elif pd.isna(row['adm1']) and pd.isna(row['adm2']):
#         print('Both adm1 & adm2 are missing: return missing')
#         return np.nan

#     # if adm1 is missing, but adm2 is recorded: infer value based on adm2
#     elif pd.isna(row['adm1']) and pd.notnull(row['adm2']):
               
#         # identify corresponding adm1-values from rest of the dataset
#         adm1_imputed_lst = panel_pd.loc[ panel_pd['adm2'] == row['adm2'], 'adm1'].drop_duplicates().to_list()
        
#         # if NaN: return Nan
#         if (len(adm1_imputed_lst) == 1) and pd.isna(adm1_imputed_lst[0]):
#             print('Can not impute adm1 because it is nan.')
#             return np.nan
        
#         # drop NaN from list
#         adm1_imputed_lst = [x for x in adm1_imputed_lst if pd.notna(x)]
        
#         # if single value identified: return identified adm1
#         if len(adm1_imputed_lst) == 1:
#             print('Imputed:', adm1_imputed_lst[0])
#             return adm1_imputed_lst[0]
#         else:
#             print('Returning first of multiple identified corresponding adm1 values of:', adm1_imputed_lst)
#             return adm1_imputed_lst[0]
    
#     else:
#         print('NaN.')
#         return np.nan
    
# # assign imputed adm1-value
# panel_pd['adm1'] = panel_pd.apply(imputeADM1, axis = 1)

# inspect recorded & imputed adm1-values
panel_pd['adm1'].isna().sum()
panel_pd['adm1'].value_counts().sort_values()
# adm2_lst = panel_pd['adm2'].drop_duplicates().to_list()
# adm2WithoutADM1_lst = panel_pd.loc[panel_pd['adm1'].isna(), 'adm2'].drop_duplicates().to_list()



## drop redundant geographic identifiers
panel_pd.drop( ['tradAuthority_ID', 'district_tradAuthority_mix'], axis=1, inplace=True)

# set adm3 & 4 to nan
panel_pd['adm3'] = np.nan
panel_pd['adm4'] = np.nan


# specify GPS-coordinates to refer to enumeration areas (i.e., community level: code 3)
panel_pd['GPS_level'] = 3


### rename variables
panel_pd.rename({
    # 'lat': 'latitude',
    # 'lon': 'longitude',
    'hh_ID': 'hhID',
    'field_ID': 'fieldID',
    'plot_ID': 'plotID',
    'areaPlotGPS_ha': 'plot_area_measured_ha',
    'areaPlotReported_ha': 'plot_area_reported_ha',
    'areaPlotReported': 'plot_area_reported_localUnit',
    'areaPlotReported_unit': 'localUnit_area',
    'plot_cropFrac': 'crop_area_share',
    'seeding_year': 'planting_year',
    'seeding_month': 'planting_month',
    'harvestStart_month': 'harvest_month_begin',
    'harvestEnd_month': 'harvest_month_end',
    'harvestStart_year': 'harvest_year_begin',
    'harvestEnd_year': 'harvest_year_end',
    }, axis=1, inplace=True)



## convert area planted to crop from fraction to percent
panel_pd['crop_area_share'] = panel_pd['crop_area_share'] * 100

## set redundant columns to nan
panel_pd['harvest_year'] = np.nan
panel_pd['harvest_month'] = np.nan


# ## derive year of harvest based on year of planting
# panel_pd['planting_year'].drop_duplicates().to_list()

# panel_pd['harvest_year_begin'] = panel_pd.apply(lambda row: row['planting_year'] if row['harvest_month_begin'] >  row['planting_month'] else (row['planting_year'] + 1), axis=1)
# panel_pd.loc[ panel_pd['harvest_month_begin'].isna(), 'harvest_year_begin'] = np.nan

# panel_pd['harvest_year_end'] = panel_pd.apply(lambda row: row['planting_year'] if row['harvest_month_end'] >  row['planting_month'] else (row['planting_year'] + 1), axis=1)
# panel_pd.loc[ panel_pd['harvest_month_end'].isna(), 'harvest_year_end'] = np.nan


# drop redundant variables
panel_pd.drop(['ea_ID', 'GS_yearStart', 'season'], axis=1, inplace=True)


### re-order columns
cols_ordered = [
'wave',
'country',
'adm1',
'adm2',
'adm3',
'adm4',
'lat',
'lon',
'GPS_level',
'hhID',
'fieldID',
'plotID',
'crop',
# 'season',
'plot_area_measured_ha',
'plot_area_reported_ha',
'plot_area_reported_localUnit',
'localUnit_area',
'crop_area_share',
'planting_year',
'planting_month',
'harvest_year_begin',
'harvest_month_begin',
'harvest_year_end',
'harvest_month_end',
'harvest_year',
'harvest_month',
'dataset_name',
'dataset_doi',
 ]

panel_pd = panel_pd[cols_ordered]



########## save overall panel to disk (without wave column)
##########################################################
panel_pd.drop('wave', axis=1).to_csv( Path( str(project_path), 'scripts', 'LSMS_MWI_harmonized', 'MWI_allWaves.csv' ), index=False )


########## save individual waves to disk
##########################################################
panel_pd['wave'].value_counts()

# loop over waves
for wave_tmp in panel_pd['wave'].drop_duplicates().to_list():
    # save to disk
    panel_pd.loc[ panel_pd['wave'] == wave_tmp].drop('wave', axis=1).to_csv( Path( str(project_path), 'scripts', 'LSMS_MWI_harmonized', f'MWI_{wave_tmp}.csv' ), index=False )


