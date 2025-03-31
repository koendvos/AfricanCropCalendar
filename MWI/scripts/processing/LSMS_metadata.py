#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Jul 14 23:57:55 2023

@author: ugrewer
"""

### package imports
##########################################################
import os
import socket
import sys
from pathlib import Path
import glob

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



### import main instances from LSMS_ingest
from scripts.processing.ingest_csv_files.LSMS_ingest import *


# ### import original variable-dictionaries of questionnaire modules
# from scripts.processing.ingest_csv_files.LSMS_ingest import modVar_dct_2010


### 
####################################################################################################################
####################################################################################################################

# load harmonized panel dataset
panel_pd = pd.read_csv( Path( str(project_path), 'scripts', 'LSMS_MWI_harmonized', 'MWI_allWaves.csv') )

# access list of harmonized variables names
varName_harmonized_lst = panel_pd.columns.to_list()
# varName_harmonized_lst = [x in varName_harmonized_lst if x not in ['', '']]


## generate metadata: list of dict
metadata_dct_lst = []

## loop over waves
for wave_tmp in panel_MWI.wave_lst:
        
    ## loop over final, harmonized variable names
    for varName_harmonized in varName_harmonized_lst:

        # create storage dict for current variable
        metadata_var_tmp = {}


        ## for wave: access variable-name conversion dictionary & dataset-identifiers
        if wave_tmp == 2010:
            # access variable-name conversion dictionary
            modVar_dct_tmp = modVar_dct_2010.copy()
            # identify dataset-identifiers
            dataset_name_tmp = MWI_2010.dataset_name
            dataset_doi_tmp = MWI_2010.dataset_doi
            # identify wave csv folder
            wave_csvFolder_tmp = MWI_2010.wave_csvFolder

        if wave_tmp == 2013:
            # access variable-name conversion dictionary
            modVar_dct_tmp = modVar_dct_2013.copy()
            # identify dataset-identifiers
            dataset_name_tmp = MWI_2013.dataset_name
            dataset_doi_tmp = MWI_2013.dataset_doi
            # identify wave csv folder
            wave_csvFolder_tmp = MWI_2013.wave_csvFolder

        if wave_tmp == 2016:
            # access variable-name conversion dictionary
            modVar_dct_tmp = modVar_dct_2016.copy()
            # identify dataset-identifiers
            dataset_name_tmp = MWI_2016.dataset_name
            dataset_doi_tmp = MWI_2016.dataset_doi
            # identify wave csv folder
            wave_csvFolder_tmp = MWI_2016.wave_csvFolder

        if wave_tmp == 2019:
            # access variable-name conversion dictionary
            modVar_dct_tmp = modVar_dct_2019.copy()
            # identify dataset-identifiers
            dataset_name_tmp = MWI_2019.dataset_name
            dataset_doi_tmp = MWI_2019.dataset_doi
            # identify wave csv folder
            wave_csvFolder_tmp = MWI_2019.wave_csvFolder


        ## add information to storage container
        metadata_var_tmp['country'] = 'Malawi'
        metadata_var_tmp['year'] = wave_tmp
        metadata_var_tmp['varName_harmonized'] = varName_harmonized
        metadata_var_tmp['dataset_name'] = dataset_name_tmp
        metadata_var_tmp['dataset_doi'] = dataset_doi_tmp                      



        ### manage variables for which no lookup shall be conducted
        ##########
        if varName_harmonized in ['wave', 'country', 'season', 'adm3', 'adm4', 'GPS_level', 'harvest_year', 'harvest_month', 'dataset_name', 'dataset_doi']:
            
            ### add information to storage container
            metadata_var_tmp['varName_source'] = np.nan
            metadata_var_tmp['varLabel_source'] = np.nan
            metadata_var_tmp['comment'] = np.nan
            


        ### for regular variables: conduct lookup
        ##########
        else:

            
            ## correct harmonized variable name (to correspond to naming convention used in variable-name conversion dictionary)
            ##########
            varName_harmonized_final = varName_harmonized
            
            if varName_harmonized == 'adm1':
                varName_harmonized = 'region'
            
            elif varName_harmonized == 'adm2':
                varName_harmonized = 'district'
                        
            elif varName_harmonized == 'latitude':
                varName_harmonized = 'lat'
            
            elif varName_harmonized == 'longitude':
                varName_harmonized = 'lon'
            
            elif varName_harmonized == 'hhID':
                varName_harmonized = 'hh_ID'
            
            elif varName_harmonized == 'fieldID':
                varName_harmonized = 'field_ID'
            
            elif varName_harmonized == 'plotID':
                varName_harmonized = 'plot_ID'
            
            elif varName_harmonized == 'crop':
                varName_harmonized = 'cropCode'

            elif varName_harmonized == 'plot_area_measured_ha':
                varName_harmonized = 'areaPlotGPS'
            
            elif varName_harmonized == 'plot_area_reported_ha':
                varName_harmonized = 'areaPlotReported'
            
            elif varName_harmonized == 'plot_area_reported_localUnit':
                varName_harmonized = 'areaPlotReported'
            
            elif varName_harmonized == 'localUnit_area':
                varName_harmonized = 'areaPlotReported_unit'
            
            elif varName_harmonized == 'crop_area_share':
                varName_harmonized = 'plot_cropFrac'
            
            elif varName_harmonized == 'planting_year':
                varName_harmonized = 'seeding_year'
            
            elif varName_harmonized == 'planting_month':
                varName_harmonized = 'seeding_month'
            
            elif varName_harmonized == 'harvest_month_begin':
                varName_harmonized = 'harvestStart_month'
            
            elif varName_harmonized == 'harvest_month_end':
                varName_harmonized = 'harvestEnd_month'

            elif varName_harmonized == 'harvest_year_begin':
                varName_harmonized = 'harvestStart_year'

            elif varName_harmonized == 'harvest_year_end':
                varName_harmonized = 'harvestEnd_year'


    
            ## loop over questionnaire modules in wave
            for moduleName, varType_dct in modVar_dct_tmp.items():
                
                ## loop over variable types (indexVars, dataVars, season)
                for varType, var_dct in varType_dct.items():
                    
                    ## skip season string
                    if varType == 'season':
                        continue
                    
                    ## loop over pairs of harmonized and source variable-names
                    for varHarmonized, varSource in var_dct.items():
            
                        ## look-up source variable name
                        if varName_harmonized == varHarmonized:
                            
                            print(f'\n#For the harmonized variable {varName_harmonized}, the following corresponding values have been identified:')
                            print('Source variable name', varSource)
                            
                            # open label file
                            # print('Path to module is:', os.path.join( wave_csvFolder_tmp, 'labels', f'{moduleName}_labels.csv' ))
                            module_label_pd = pd.read_csv( os.path.join( wave_csvFolder_tmp, 'labels', f'{moduleName}_labels.csv' ), encoding = "ISO-8859-1" )
    
                            ## lookup variable label
                            if module_label_pd.loc[ module_label_pd['name'] == varSource, 'varlab'].empty:
                                varLabel_tmp = np.nan
                            else:
                                varLabel_tmp = module_label_pd.loc[ module_label_pd['name'] == varSource, 'varlab'].item()

                            

                            ### add information to storage container
                            ##########
                            
                            ## check if key already present in dict
                            if 'varName_source' in metadata_var_tmp:
                                
                                # skip if current info is identical to previous info
                                if metadata_var_tmp['varName_source'].lower() == varSource.lower():
                                    continue
                                else:
                                    # append to existing value
                                    metadata_var_tmp['varName_source'] = f'{metadata_var_tmp["varName_source"]}; {varSource}'
                                
                            else:
                                metadata_var_tmp['varName_source'] = varSource



                            ## check if key already present in dict
                            if 'varLabel_source' in metadata_var_tmp:
                                
                                # skip if current info is identical to previous info
                                if metadata_var_tmp['varLabel_source'].lower() == varLabel_tmp.lower():
                                    continue
                                else:
                                    # append to existing value
                                    metadata_var_tmp['varLabel_source'] = f'{metadata_var_tmp["varLabel_source"]}; {varLabel_tmp}'
                            else:
                                metadata_var_tmp['varLabel_source'] = varLabel_tmp


                            metadata_var_tmp['comment'] = np.nan


        ### store results to overall storage-container
        ##########
        metadata_dct_lst.append( metadata_var_tmp )
        



### generate metadata-df
##########
metadata_pd = pd.DataFrame(metadata_dct_lst)    



### correct overwritten household-identifier in 2013-wave
##########
metadata_pd.loc[ (metadata_pd['year'] == 2013) & (metadata_pd['varName_harmonized'] == 'hhID'), 'varName_source' ] = 'case_id'
metadata_pd.loc[ (metadata_pd['year'] == 2013) & (metadata_pd['varName_harmonized'] == 'hhID'), 'varLabel_source' ] = 'IHS3 Baseline case_id as in IHS3 Public Data'


### complete incomplete variable labels
##########
metadata_pd.loc[ (metadata_pd['year'] == 2013) & (metadata_pd['varName_harmonized'] == 'planting_month'), 'varLabel_source' ] = 'When did you plant the seeds for the [CROP] on this [PLOT] during the 2012/2013 rainy season? (Month); When did you plant the seeds for the [CROP] on this [PLOT] during the 2013 dry (dimba) season? (Month)'
metadata_pd.loc[ (metadata_pd['year'] == 2013) & (metadata_pd['varName_harmonized'] == 'planting_year'), 'varLabel_source' ] = 'When did you plant the seeds for the [CROP] on this [PLOT] during the 2012/2013 rainy season? (YEAR 4-DIGIT); When did you plant the seeds for the [CROP] on this [PLOT] during the 2013 dry (dimba) season? (YEAR 4-DIGIT)'



### add comments
##########
metadata_pd.loc[ metadata_pd['varName_harmonized'] == 'wave', 'comment'] = 'The wave indicates the first year of the respective IHS data-collection that typically extended into the subsequent calendar year.'
metadata_pd.loc[ metadata_pd['varName_harmonized'] == 'plot_area_measured_ha', 'comment'] = 'For conversion of various area units to hectare, the following parameters have been used: 4046.9 (sqm in an acre), 2.471 (acres in a ha), 11959.9 (yards in a ha).'
metadata_pd.loc[ metadata_pd['varName_harmonized'] == 'plot_area_reported_ha', 'comment'] = 'For conversion of various area units to hectare, the following parameters have been used: 4046.9 (sqm in an acre), 2.471 (acres in a ha), 11959.9 (yards in a ha).'
metadata_pd.loc[ metadata_pd['varName_harmonized'] == 'crop_area_share', 'comment'] = 'The percentage of plot area cultivated by a crop was assumed as: 12.5 % if indicated "less than 1/4", 25 % if indicated "1/4", 37.5 % if indicated "less than 1/2", 50 % if indicated "1/2", 62.5 % if indicated "less than 3/4", 75 % if indicated "3/4", 87.5 % if indicated "more than 3/4", 100 % if indicated as fully occupied by a single crop. For many plots, any indication on whether the crop was fully cultivated by a single crop is missing: Whenever a plot is not intercropped and not indicated as only partially being cropped, then we assume that the plot is fully under the target crop.'
# metadata_pd.loc[ metadata_pd['varName_harmonized'] == 'harvest_year_begin', 'comment'] = 'The year of the harvest start was not explicitly recorded in the IHS. We assumed the harvest to occur in the same year as planting, if the harvest month occured later in the calendar year than the planting month. Otherwise, the harvest year was assumed as the year subsequent to the planting year.'
# metadata_pd.loc[ metadata_pd['varName_harmonized'] == 'harvest_year_end', 'comment'] = 'The year of the harvest end was not explicitly recorded in the IHS. We assumed the harvest to occur in the same year as planting, if the harvest month occured later in the calendar year than the planting month. Otherwise, the harvest year was assumed as the year subsequent to the planting year.'
metadata_pd.loc[ metadata_pd['varName_harmonized'] == 'crop', 'comment'] = 'Crop names were harmonized for spelling. Crop names in Chichewa for which the English translation was known, were converted to their English name.'
metadata_pd.loc[ metadata_pd['varName_harmonized'] == 'lon', 'comment'] = 'Geo-coordinates have been set to missing for reported values of 0N/0E or when one coordinate was reported as 0 and the other coordinate as missing.'
metadata_pd.loc[ metadata_pd['varName_harmonized'] == 'lat', 'comment'] = 'Geo-coordinates have been set to missing for reported values of 0N/0E or when one coordinate was reported as 0 and the other coordinate as missing.'
metadata_pd.loc[ metadata_pd['varName_harmonized'] == 'season', 'comment'] = 'The type of season (major vs minor) has been identified based on the seasonal focus of the respective sections of the survey questionnaire. The IHS contains separate questionnaire sections for the major and minor growing season.'

metadata_pd.loc[ (metadata_pd['year'] == 2010) & (metadata_pd['varName_harmonized'] == 'fieldID'), 'comment'] = 'The 2010 survey wave of the IHS did not record any field-identifiers but exclusively used plot-identifiers.'
metadata_pd.loc[ (metadata_pd['year'] == 2013) & (metadata_pd['varName_harmonized'] == 'dataset_doi'), 'comment'] = 'Of the Malawian panel dataset "MWI_2010-2013_IHPS_v01_M", which includes data for both the 2010 and 2013 survey waves, we exclusively considered data from the 2013 survey wave. Data for the 2010 survey wave was instead sourced separately from the cross-sectional dataset “MWI_2010_IHS-III_v01_M”. For the 2013 survey wave, no cross-sectional dataset is available.'
metadata_pd.loc[ metadata_pd['varName_harmonized'] == 'harvest_year_begin', 'comment'] = 'The IHS surveys collected data on the harvesting year exclusively for tree and perennial crops, but not for annual crops.'
metadata_pd.loc[ metadata_pd['varName_harmonized'] == 'harvest_year_end', 'comment'] = 'The IHS surveys collected data on the harvesting year exclusively for tree and perennial crops, but not for annual crops.'



'''
### add comment: harmonised variable was constructed from two variables in the source dataset
twoSourceVars_commentStr = "When 'varName_source' records several values separated by a semicolon, the harmonized data recorded in 'varName_harmonized' has been derived from several variables in the LSMS source data - e.g., due to separate questionnaire modules for the major and minor season. In those cases, the variable 'pctMissing_source' refers to the total percentage of missing values across all listed variables from the LSMS source data."

# loop over metadata-rows
for index, row in metadata_pd.copy().iterrows():
    
    # check that row has some corresponding variable in the source dataset
    if pd.notna( row['varName_source'] ):
        
        # check if row has two corresponding variables in the source dataset
        if ';' in row['varName_source']:
            
            # check if variable has no metadata-comment yet
            if pd.isna( row['comment'] ):
                # add new comment
                metadata_pd.loc[ (metadata_pd['dataset_name'] == row['dataset_name']) & (metadata_pd['varName_source'] == row['varName_source']), 'comment'] = twoSourceVars_commentStr

            # if variable has already a metadata-comment
            else:
                # append to existing comment               
                metadata_pd.loc[ (metadata_pd['dataset_name'] == row['dataset_name']) & (metadata_pd['varName_source'] == row['varName_source']), 'comment'] = row['comment'] + ' ' + twoSourceVars_commentStr
            
'''



### add: percentage of missing values
##########

### empty data storage: missing value count
missingValues_pd = pd.DataFrame( {
    'dataset_name': [],
    'module_source': [],
    'varName_source': [],
    'varName_harmonized': [],
    'countMissing_source': [],
    'countMissing_harmonized': [],
    'countTotal_source': [],
    'countTotal_harmonized': [],
    } )



# loop over metadata-rows
for index, row in metadata_pd.copy().iterrows():

    ## check if row has no corresponding variables in source dataset
    if pd.isna( row['varName_source'] ):
        continue

    ## check if varName_source is a single variable
    if ';' not in row['varName_source']:
        # store source-variable to list
        sourceVars_lst = [ row['varName_source'] ]
    
    else:
        ## convert multiple source-variables to entries in list
        sourceVars_lst = row['varName_source'].split(';')
        sourceVars_lst = [x.strip() for x in sourceVars_lst]

        
    ## loop over variables in source dataset
    for sourceVar in sourceVars_lst:
    
        print('\n\n\n##### Starting to work on source variable:', sourceVar)
        print('Corresponding to year:', row['year'])
        print('Originating from dataset:', row['dataset_name'])

    
        ### access originating survey-module in raw LSMS-data
        
        # loop over module-variable dictionaries
        for moduleCollection_name, moduleCollection_dct in {
                        'modVar_dct_2010': modVar_dct_2010, 
                        'modVar_dct_2013': modVar_dct_2013, 
                        'modVar_dct_2016': modVar_dct_2016, 
                        'modVar_dct_2019': modVar_dct_2019,
                        }.items():
            
            # skip if module_dct concerns irrelevant wave
            if str( row['year'] ) not in moduleCollection_name:
                continue
            print('\n### Starting to work on moduleCollection_dct:', moduleCollection_name, '\n')
    
            
            # loop over module-dicts for current survey-wave
            for module_name, module_dct in moduleCollection_dct.items():
    
                # check if variable originated in current module
                if sourceVar in list(module_dct['indexVars'].values()) + list(module_dct['dataVars'].values()) :
                # if sourceVar in module_dct['dataVars'].values():
                    print('# SourceVar has been identified to originate from module:', module_name, '\n')
                    
                    
                    # access corresponding folder name
                    if row['year'] == 2010:
                        wave_folder_tmp = '2010_2011'
                    elif row['year'] == 2013:
                        wave_folder_tmp = '2010_2013_panel'
                    elif row['year'] == 2016:
                        wave_folder_tmp = '2016_2017'
                    elif row['year'] == 2019:
                        wave_folder_tmp = '2019_2020'
                    else:
                        wave_folder_tmp = np.nan


                    # identify file path of target module
                    module_path = glob.glob( os.path.join(data_folder_LSMS, wave_folder_tmp, '*_DtaToCsvExport', f'{module_name}.csv' ) )
    
                    # catch if no module could be identified
                    if len( module_path ) == 0:
                        print('################## Attention ##################')
                        print('Could not find any module-csv on disk for module_path:', module_path)
                        print('Inspected path was:', os.path.join(data_folder_LSMS, wave_folder_tmp, '*_DtaToCsvExport', f'{module_name}.csv' ))
                        break
                    
                    # convert list to path
                    module_path = module_path[0]
    
    
                    ### open raw source LSMS-module
                    try:
                        pd.read_csv( module_path, encoding='utf-8' )
                    except UnicodeDecodeError:
                        LSMS_source_pd = pd.read_csv( module_path, encoding = "ISO-8859-1" )
                    else:
                        LSMS_source_pd = pd.read_csv( module_path, encoding='utf-8' )

                    
                    ### replace declared missing value operator to NaN
    
    
    
                    ### reformat all column names to lowercase
                    LSMS_source_pd.columns = map(str.lower, LSMS_source_pd.columns)
                    
                    ### compute missing values in raw LSMS-source data
                    LSMS_source_nanCount = LSMS_source_pd[sourceVar].isna().sum()
                    # LSMS_source_nanPercent = (LSMS_source_nanCount / len(LSMS_source_pd)) * 100
                    
                    ### compute total values in raw LSMS-source data
                    LSMS_source_totalCount = len( LSMS_source_pd )

    
                    ### compute missing values in harmonized data
                    dataHarmonized_nanCount = panel_pd.loc[ (panel_pd['dataset_name'] == row['dataset_name'].lower()), row['varName_harmonized'] ].isna().sum()
                    # dataHarmonized_nanPercent = (dataHarmonized_nanCount / len(panel_pd.loc[panel_pd['dataset_name'] == row['dataset_name'].lower()] )) * 100

                    ### compute total values in harmonized data
                    dataHarmonized_totalCount = len(panel_pd.loc[panel_pd['dataset_name'] == row['dataset_name'].lower()] )
    
                    ## save results to storage-container
                    missingValues_pd.loc[ len(missingValues_pd) ] = {
                        'dataset_name': row['dataset_name'],
                        'module_source': module_name,
                        'varName_source': sourceVar,
                        'varName_harmonized': row['varName_harmonized'],
                        'countMissing_source': LSMS_source_nanCount,
                        'countMissing_harmonized': dataHarmonized_nanCount,
                        'countTotal_source': LSMS_source_totalCount,
                        'countTotal_harmonized': dataHarmonized_totalCount,
                        }
                    


### aggregate storage container: from module-level to dataset-level
missingValues_aggregated_pd = missingValues_pd[['dataset_name', 'varName_harmonized', 'countMissing_source', 'countMissing_harmonized', 'countTotal_source', 'countTotal_harmonized']].groupby(['dataset_name', 'varName_harmonized'], as_index = False).sum()

### calculate missing-value-percentages
missingValues_aggregated_pd['pctMissing_source'] = ( missingValues_aggregated_pd['countMissing_source'] / missingValues_aggregated_pd['countTotal_source'] ) * 100
missingValues_aggregated_pd['pctMissing_harmonized'] = ( missingValues_aggregated_pd['countMissing_harmonized'] / missingValues_aggregated_pd['countTotal_harmonized'] ) * 100


### transfer missing value-results into metadata
metadata_pd = pd.merge(
    metadata_pd, 
    missingValues_aggregated_pd[[
        'dataset_name',
        'varName_harmonized',
        'pctMissing_source',
        'pctMissing_harmonized',        
        ]], 
    how="outer", 
    on=[
        'dataset_name',
        'varName_harmonized',
        ]
    )



### drop 'wave' variable from all datasets
metadata_pd.drop( metadata_pd[metadata_pd['varName_harmonized'] == 'wave'].index, inplace=True )



########## save overall panel metadata to disk
##########################################################
metadata_pd.to_csv( Path( str(project_path), 'scripts', 'LSMS_MWI_harmonized', 'MWI_allWaves_metadata.csv' ), index=False )


########## save individual waves' metadata to disk
##########################################################
metadata_pd['year'].value_counts()

# loop over waves
for wave_tmp in metadata_pd['year'].drop_duplicates().to_list():
    # save to disk
    metadata_pd.loc[ metadata_pd['year'] == wave_tmp].to_csv( Path( str(project_path), 'scripts', 'LSMS_MWI_harmonized', f'MWI_{wave_tmp}_metadata.csv' ), index=False )
