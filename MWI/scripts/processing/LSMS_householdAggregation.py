#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Jan  5 16:25:02 2023

@author: ugrewer

Aggregate LSMS survey at household level.

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

import gc


### setup
##########################################################

### identify project directory
# TUXEDO-laptop
if 'ugrewer-TUXEDO' in socket.gethostname():
    project_path = '/datadisk2/Scientific/Study_PhD/07_papers/2022.04_shortVars'
# else: use documents folder
else:
    project_path = str(Path(os.path.expanduser("~")) / Path('Documents/Scientific/Study_PhD/07_papers/2022.04_shortVars'))


# add project directory to system path (note: system path expects only strings to be added - not pathlib_objects)
if project_path not in sys.path:
    sys.path.append( str(project_path) )

#set working directory to project path
os.chdir(project_path)

#import major path locations
from defPaths import *



### load dataset & preliminaries
####################################################################################################################
####################################################################################################################

# load clean panel-df
panel_pd = pd.read_csv( Path( str(project_path), 'LSMS_MWI', 'MWI_panel_cleaned.csv') )

# format date-columns as datetime
for col_tmp in ['planting_date', 'harvestStart_date', 'harvestEnd_date', 'harvestMid_date']:
    panel_pd[col_tmp] = pd.to_datetime(panel_pd[col_tmp], format="%Y-%m-%d")





### aggregate data at household-level
####################################################################################################################
####################################################################################################################

# list of variables to be dropped
dropVar_lst = ['wave',
'field_ID',
'plot_ID',
'crop01',
'crop02',
'plot_lessHarvestThanPlant',
'plot_fullyCrop',
'plot_cropFrac',
'areaPlot_ha',
'seed_purchaseYear',
'fertOrg_kgProd',
'fertSyn_kgProd',
'fertSyn_kgN',
'labour_hh_days',
'labour_hired_days',
'labour_exchange_days',
'labour_total_days',
'varietyMZ',
'varietyMZ_matureGroup',
'harvestDuration',
]

# drop redundant columns
panel_pd.drop(dropVar_lst, axis=1, inplace=True)


# list of index variables
indexVar_lst = ['hh_ID',
'GS_yearStart',
'majorSeason_dum',
'lon',
'lat',
'crop',
]


# list: variables summed at household level
sumVars_lst = [
'output_kg',
'areaPlot_ha_crop',
'seed_kg',
'fertOrg_kgProd_crop',
'fertSyn_kgProd_crop',
'fertSyn_kgN_crop',
'labour_hh_days_crop',
'labour_hired_days_crop',
'labour_exchange_days_crop',
'labour_total_days_crop',
]


# list: variables converted to share of area with specific characteristics at household level
areaShareVars_lst = [
'intercropped',
'fertOrg_dum',
'pesticide_dum',
'varietyMZ_certified',
'varietyMZ_hybrid',
]


# list: variables converted to area-weighted averages at household level
areaWtAvgVars_lst = [
'varietyMZ_matureDays',
'planting_date',
'harvestStart_date',
'harvestEnd_date',
'harvestMid_date',
'CGP_duration',
]


# customized aggregation of dataframe at household-level
def householdAggregation(df_group, sumVars_lst, areaShareVars_lst, areaWtAvgVars_lst):
    ''' Customized aggregation of columns at household level. '''

    # create storage container
    results_dct = {}


    ### summation variables
    ##########

    # summation at household level
    for varSum_tmp in sumVars_lst:
        results_dct[f'{varSum_tmp}_hhSum'] = [df_group[varSum_tmp].sum()]


    ### area-share variables
    ##########

    # loop over area-share variables
    for varAreaShare_tmp in areaShareVars_lst:

        # compute total household area
        totalArea_tmp = df_group['areaPlot_ha_crop'].sum()

        # initiate area impacted by temporary variable of interest
        areaImpacted_tmp = 0

        # loop over each plot of household
        for row_index, row_tmp in df_group.iterrows():

            # test if indicator variable is True
            if row_tmp[varAreaShare_tmp] == 1:
                # add area of plot
                areaImpacted_tmp = np.nansum( [areaImpacted_tmp, row_tmp['areaPlot_ha_crop'] ] )
                # areaImpacted_tmp += row_tmp['areaPlot_ha_crop']

        # compute area-share for temporary household
        areaShare_tmp = areaImpacted_tmp / totalArea_tmp

        # append to results-dict
        results_dct[f'{varAreaShare_tmp}_hhAreaShare'] = areaShare_tmp
        


    ### area-weighted averages
    ##########

    # loop over variables for which weighted-average shall be computed
    for varAreaWtAvg_tmp in areaWtAvgVars_lst:
        
        # print('\nStarting to work on var:', varAreaWtAvg_tmp)
        
        # compute total household area
        totalArea_tmp = df_group['areaPlot_ha_crop'].sum()

        # initiate sum of area-weighted values        
        areaWtSum_tmp = 0


        ## if variable is not a timestamp
        if not pd.api.types.is_datetime64_ns_dtype(panel_pd[varAreaWtAvg_tmp]):
            
            # loop over each plot of household
            for row_index, row_tmp in df_group.iterrows():
    
                # compute sum of area-weighted values
                areaWtSum_tmp = np.nansum([ areaWtSum_tmp, (row_tmp['areaPlot_ha_crop'] * row_tmp[varAreaWtAvg_tmp]) ])
                # areaWtSum_tmp += row_tmp['areaPlot_ha_crop'] * row_tmp[varAreaWtAvg_tmp]
                           
            # compute weighted-average
            areaWtAvg_tmp = areaWtSum_tmp / totalArea_tmp


        ## if variable is timestamp
        else:

            # identify earliest date
            date_earliest = df_group[varAreaWtAvg_tmp].min()

            # initiate area-weighted sum
            areaWtSum_tmp = 0


            # loop over each plot of household
            for row_index, row_tmp in df_group.iterrows():

                # print('\n***Working on planting date:', row_tmp['planting_date'])


                ## test if date is identical to start-date
                if row_tmp[varAreaWtAvg_tmp] == date_earliest:

                    # grow area-weighted sum
                    areaWtSum_tmp = np.nansum( [areaWtSum_tmp, (row_tmp['areaPlot_ha_crop'] * 1) ])
                    # areaWtSum_tmp += row_tmp['areaPlot_ha_crop'] * 1


                ## all other observed dates 
                else:
                    
                    # print('\n***Calculating diff for multiple days.')
                    # convert date to daycount differing from earliest day (starting from 1)
                    dayCount_tmp = (row_tmp[varAreaWtAvg_tmp] - date_earliest).days
                    # add one day to account for earliest reference-date
                    dayCount_tmp += 1
                    
                    # grow area-weighted sum of days
                    areaWtSum_tmp = np.nansum([ areaWtSum_tmp, (row_tmp['areaPlot_ha_crop'] * dayCount_tmp) ])
                    # areaWtSum_tmp += row_tmp['areaPlot_ha_crop'] * dayCount_tmp


            # compute weighted-difference (in days)
            areaWtDiff_tmp = areaWtSum_tmp / totalArea_tmp

            # subtract earlier added additional day
            areaWtDiff_tmp -= 1
            
            # manage: all dates are NAN
            if pd.isnull(date_earliest):
                areaWtAvg_tmp = np.NaN
            # manage: all but earliest-dates are NAN
            elif pd.notnull(date_earliest) and pd.isnull(areaWtDiff_tmp):
                areaWtAvg_tmp = date_earliest
            # all dates valid
            else:
                # add days to reference date
                areaWtAvg_tmp = date_earliest + datetime.timedelta(days = round(areaWtDiff_tmp) )

            
        ### append to results-dict
        results_dct[f'{varAreaWtAvg_tmp}_hhAreaWtAvg'] = areaWtAvg_tmp


    ### return household-level aggregated dataframe
    return pd.DataFrame(results_dct)



# generate dataframe aggregated at household-level
panel_hhLevel_pd = panel_pd.groupby(indexVar_lst).apply(householdAggregation, sumVars_lst = sumVars_lst, areaShareVars_lst = areaShareVars_lst, areaWtAvgVars_lst = areaWtAvgVars_lst)

# remove old index-column & set correct index
panel_hhLevel_pd = panel_hhLevel_pd.reset_index().drop('level_6', axis=1).set_index(['hh_ID', 'GS_yearStart', 'majorSeason_dum'])


### save result back to disk
#####
panel_hhLevel_pd.to_csv( Path( str(project_path), 'LSMS_MWI', 'MWI_panel_hhLevel.csv' ) )


# some descriptives
panel_hhLevel_pd['varietyMZ_certified_hhAreaShare'].describe()
panel_hhLevel_pd['varietyMZ_hybrid_hhAreaShare'].describe()
panel_hhLevel_pd['varietyMZ_matureDays_hhAreaWtAvg'].describe()



### identify balanced-panel observations
##########
def get_balancedPanel_dum(df, row):
    ''' Identify if more than one observations exist for current hh_ID. '''
    if len( df.loc[ df['hh_ID'] == row['hh_ID']] ) > 1:
        return True
    else:
        return False


panel_hhLevel_pd.reset_index(inplace=True)   
panel_hhLevel_pd['panel_dum'] = panel_hhLevel_pd.apply( lambda row: get_balancedPanel_dum(panel_hhLevel_pd, row), axis=1)
print('The number of rows constituting balanced panel observations AT HOUSEHOLD LEVEL are:')
panel_hhLevel_pd['panel_dum'].value_counts()

