#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun May  1 11:44:03 2022

@author: ugrewer

Clean ingested panel dataset.
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



### define constants and parameters
####################################################################################################################
####################################################################################################################

# acre to square-meter conversion
sqm_in_acre = 4046.8564224
acre_in_ha = 2.4710538147
yards_in_ha = 11959.900463011




### clean panel dataset
####################################################################################################################
####################################################################################################################



# load ingested panel-df
panel_pd = pd.read_csv( Path( str(project_path), 'scripts', 'LSMS_MWI_ingested', 'MWI_panel_ingested.csv') )

# get list of column-names
colNames_lst = panel_pd.columns.to_list()




### convert all string-columns to lower case
##########################################################

# loop over all object-columns
# for obj_col in panel_pd.loc[:, panel_pd.dtypes == object]:
for obj_col in panel_pd.select_dtypes(include=['object']).columns:
    # convert object-column to lower case
    panel_pd[obj_col] = panel_pd[obj_col].apply( lambda cell: str(cell).lower() if pd.isna(cell)==False else np.nan)



### plot-area
##########################################################


### convert gps-measured plot area to hectares
#####
panel_pd['areaPlotGPS_ha'] = panel_pd['areaPlotGPS'] / acre_in_ha



### convert self-reported plot area to hectares
#####

# identify "other units"
panel_pd['areaPlotReported_unitOther'].value_counts()
# update "unit" for known "other units"
panel_pd.loc[ panel_pd['areaPlotReported_unitOther']=='yards', 'areaPlotReported_unit'] = 'yards'
panel_pd.loc[ panel_pd['areaPlotReported_unitOther']=='acre', 'areaPlotReported_unit'] = 'acre'
panel_pd.loc[ panel_pd['areaPlotReported_unitOther']=='acres', 'areaPlotReported_unit'] = 'acre'


panel_pd['areaPlotReported_unit'].value_counts()
# calculate conversion factor from current unit to square-meters
panel_pd['areaPlotReported_ha_converter'] = panel_pd['areaPlotReported_unit'].copy()
panel_pd['areaPlotReported_ha_converter'].replace({
                                                    'acre': acre_in_ha,
                                                    'square meters': 10000,
                                                    'hectare': 1,
                                                    'yards': yards_in_ha,
                                                    'other (specify)': np.nan,
                                                    '.a': np.nan,
                                                    }, inplace=True)

panel_pd['areaPlotReported_ha_converter'] = pd.to_numeric(panel_pd['areaPlotReported_ha_converter'])

# compute reported plot-area in hectares
panel_pd['areaPlotReported_ha'] = panel_pd['areaPlotReported'] / panel_pd['areaPlotReported_ha_converter']

# set any infinity area-values to nan
panel_pd['areaPlotReported_ha'].replace([np.inf, -np.inf], np.nan, inplace=True)


# def get_plotArea_ha(df_row):
#     ''' Derive the plot-area in hectare. If available: use gps-measured data, otherwise self-reported data. If negative, replace with NaN. '''

#     # if available and not 0 or NaN: return gps-measured area
#     if pd.notna( df_row['areaPlotGPS_ha'] ) and (df_row['areaPlotGPS_ha'] > 0):
#         return df_row['areaPlotGPS_ha']

#     # else, if not 0 or NaN:: return self-reported area
#     elif pd.notna( df_row['areaPlotReported_ha'] ) and (df_row['areaPlotReported_ha'] > 0):
#         return df_row['areaPlotReported_ha']

#     # else: if both 0, or if one 0 and one NaN: return 0
#     elif ( df_row['areaPlotGPS_ha']==0 ) or ( df_row['areaPlotReported_ha']==0 ):
#         return 0

#     # else: set to NaN
#     else:
#         return np.nan

# # derive field area (if available: gps-measures, else: self-reported)
# panel_pd['areaPlot_ha'] = panel_pd.apply(get_plotArea_ha, axis=1)

# # overview of cumputed plot-area in hectares
# panel_pd['areaPlot_ha'].describe()
# panel_pd['areaPlot_ha'].isna().sum()

# delete redundant columns
panel_pd.drop([ 'areaPlotGPS', 'areaPlotReported_unitOther', 'areaPlotReported_ha_converter'], axis=1, inplace=True)
# panel_pd.drop(['areaPlotReported', 'areaPlotReported_unit', 'areaPlotGPS', 'areaPlotReported_unitOther', 'areaPlotGPS_ha', 'areaPlotReported_ha_converter', 'areaPlotReported_ha'], axis=1, inplace=True)



### gps-coordinates
##########################################################

# set Null-Island locations (lon=0, lat=0) to missing
panel_pd.loc[ (panel_pd['lon'] == 0) & (panel_pd['lat'] == 0), 'lon'] = np.nan
panel_pd.loc[ (panel_pd['lon'] == 0) & (panel_pd['lat'] == 0), 'lat'] = np.nan

panel_pd.loc[ (panel_pd['lon'] == 0) & (panel_pd['lat'].isna()), 'lon'] = np.nan
panel_pd.loc[ (panel_pd['lon'].isna()) & (panel_pd['lat'] == 0), 'lat'] = np.nan



########## major season dummy
##########################################################
# clean dummy variable to 0-1 coding
panel_pd['season'].value_counts()

panel_pd['majorSeason_dum'] = panel_pd['season'].copy()
panel_pd['majorSeason_dum'].replace({'minor': 0, 'major': 1}, inplace=True)
panel_pd['majorSeason_dum'].value_counts()

# panel_pd.drop( ['season'], axis=1, inplace=True)



# ########## field_usage
# ##########################################################
# panel_pd['field_usage'].value_counts()

# panel_pd['cultivatedField_dum'] = np.nan
# panel_pd.loc[ panel_pd['field_usage'].notna(), 'cultivatedField_dum'] = 0
# panel_pd.loc[ panel_pd['field_usage']=='cultivated', 'cultivatedField_dum'] = 1

# panel_pd['cultivatedField_dum'].value_counts()
# panel_pd.drop( ['field_usage'], axis=1, inplace=True)




########## start-year of last cultivated major and minor growing season
##########################################################
# panel_pd['lastMajor_hhCult_dum'].value_counts()
# panel_pd['lastMinor_hhCult_dum'].value_counts()

panel_pd['lastMajor'].drop_duplicates()
panel_pd['lastMinor'].drop_duplicates()


def get_GS_yearStart( season, row ):
    ''' Identify the start-year of last major and/or minor growing season. '''

    if season == 'major':

        if pd.isna(row['lastMajor']):
            return np.nan
        else:
            return int( row['lastMajor'].split('/')[0] )


    elif season == 'minor':
        
        if pd.isna(row['lastMinor']):
            return np.nan

        else:        
            return int( row['lastMinor'] )


    else:
        return np.nan


# derive start-year of last cultivated major and minor growing season
panel_pd['lastMajor_yearStart'] = panel_pd.apply( lambda row: get_GS_yearStart('major', row), axis=1)
panel_pd['lastMinor_yearStart'] = panel_pd.apply( lambda row: get_GS_yearStart('minor', row), axis=1)

panel_pd['lastMajor_yearStart'].value_counts()
panel_pd['lastMinor_yearStart'].value_counts()



########## start-year of current growing season
##########################################################

panel_pd['GS_yearStart'] = np.nan
panel_pd.loc[ panel_pd['majorSeason_dum']==1, 'GS_yearStart'] = panel_pd['lastMajor_yearStart']
panel_pd.loc[ panel_pd['majorSeason_dum']==0, 'GS_yearStart'] = panel_pd['lastMinor_yearStart']

panel_pd['GS_yearStart'].value_counts()
panel_pd.drop( ['lastMajor', 'lastMinor', 'lastMajor_yearStart', 'lastMinor_yearStart'], axis=1, inplace=True)



########## planting
##########################################################

### planting month
panel_pd['seeding_month'].drop_duplicates()

# # set '20' to nan
# panel_pd['seeding_month'].replace({'20': np.nan}, inplace=True)

panel_pd['seeding_month'].replace({'january': 1,
                                    'february': 2,
                                    'march': 3,
                                    'april': 4,
                                    'may': 5,
                                    'june': 6,
                                    'july': 7,
                                    'august': 8,
                                    'september': 9,
                                    'october': 10,
                                    'november': 11,
                                    'december': 12,
                                    'NaN': np.nan,
                                    }, inplace=True)

panel_pd['seeding_month'].value_counts()



# ### planting year
# panel_pd['seeding_year'].drop_duplicates().to_list()

# # keep a copy of current variable values
# panel_pd['seeding_year_numericHelper'] = panel_pd['seeding_year'].copy()
# # Convert valid numeric strings to numeric values & convert invalid values to NaN
# panel_pd['seeding_year'] = pd.to_numeric(panel_pd['seeding_year'], errors='coerce')
# # Overwrite NaN values with original non-numeric strings
# panel_pd['seeding_year'].fillna(panel_pd['seeding_year_numericHelper'], inplace=True)
# # drop helper column
# panel_pd.drop(['seeding_year_numericHelper'], axis=1, inplace=True)




########## harvesting
##########################################################
panel_pd['harvestStart_month'].value_counts()
panel_pd['harvestEnd_month'].value_counts()


# # replace unreasonable values
# panel_pd['harvestStart_month'].replace({
#     '0': np.nan,
#     '84': np.nan,
#     '48': np.nan,
#     }, inplace=True)

# panel_pd['harvestEnd_month'].replace({
#     '0': np.nan,
#     }, inplace=True)



# replace month-strings with month-integers
panel_pd['harvestStart_month'].replace({'january': 1,
                                    'february': 2,
                                    'march': 3,
                                    'april': 4,
                                    'may': 5,
                                    'june': 6,
                                    'july': 7,
                                    'august': 8,
                                    'september': 9,
                                    'october': 10,
                                    'november': 11,
                                    'december': 12,
                                    'NaN': np.nan,
                                    }, inplace=True)

panel_pd['harvestEnd_month'].replace({'january': 1,
                                    'february': 2,
                                    'march': 3,
                                    'april': 4,
                                    'may': 5,
                                    'june': 6,
                                    'july': 7,
                                    'august': 8,
                                    'september': 9,
                                    'october': 10,
                                    'november': 11,
                                    'december': 12,
                                    'NaN': np.nan,
                                    }, inplace=True)






########## household is cultivating
##########################################################
panel_pd['hhCultivated_dum'].drop_duplicates()

# drop variable (focus on whether plot is cultivated, not on whether this household is cultivating)
panel_pd.drop(['hhCultivated_dum'], axis=1, inplace=True)








########## intercropping
##########################################################
panel_pd['cropStand'].drop_duplicates().to_list()

panel_pd['intercropped'] = panel_pd['cropStand'].copy()
panel_pd['intercropped'].replace({
    'row intercrop': 1,
    'mixed stand': 1,
    'pure stand / sole': 0,
    'relay intercrop': 1,
    'strip intercrop': 1,
    'pure stand': 0,
    'plantation': 0,
    'scattered': 1,
    }, inplace=True)

panel_pd['intercropped'].drop_duplicates().to_list()
panel_pd['intercropped'].value_counts()

# set unreasonable value to NaN
panel_pd['intercropped'] = panel_pd['intercropped'].replace('3', np.nan)






# ########## clean plot_lessHarvestThanPlant
# ##########################################################
# panel_pd['plot_lessHarvestThanPlant'].drop_duplicates().to_list()
# panel_pd['plot_lessHarvestThanPlant'].replace({'no': 0, 'yes': 1}, inplace=True)




########## derive resource use for intercropped plots
##########################################################

### derive fraction of area cultivated by crop

# identify if plot was fully occupied by single crop
panel_pd['plot_fullyCrop'].drop_duplicates().to_list()
panel_pd['plot_fullyCrop'].replace({
    'no': 0, 
    'yes': 1,
    '3': np.nan,
    }, inplace=True)

panel_pd['plot_fullyCrop'].isna().sum()
panel_pd['plot_fullyCrop'].value_counts()


# identify fraction of plot cropped
panel_pd['plot_cropFrac'].drop_duplicates().to_list()
panel_pd['plot_cropFrac'].value_counts()
panel_pd['plot_cropFrac'].replace({
    'less than 1/4': 0.125,
    '1/4': 0.25,
    'less than 1/2': 0.375,
    '1/2': 0.5,
    'less than 3/4': 0.625,
    '3/4': 0.75,
    'more than 3/4': 0.875,
    }, inplace=True)


# # assumption: if plot not intercropped & plot_cropFrac is NaN: consider plot_cropFrac as 1 (even if plot_fullyCrop is NaN)
# def clean_plot_cropFrac(row):
#     ''' Assign that entire plot is occupied by main crop if it was indicated as fully cropped by same crop'''
    
#     # if plot_cropFrac already recorded: return
#     if pd.notnull(row['plot_cropFrac']):
#         return row['plot_cropFrac']
    
#     elif row['plot_fullyCrop'] == 1:
#         return 1


# assumption: if plot not intercropped & plot_cropFrac is NaN: consider plot_cropFrac as 1 (even if plot_fullyCrop is NaN)
def clean_plot_cropFrac(row):
    ''' Specify the fraction of a plot that is occupied by a given crop.
    Assign that entire plot is occupied by main crop if:
        (i) plot is indicated as fully cropped AND plot is not intercropped.'''
    
    # if plot_cropFrac already recorded: return plot_cropFrac
    if pd.notnull(row['plot_cropFrac']):
        return row['plot_cropFrac']
    
    else:
        # filter: plot is indicated as fully cropped AND plot is not intercropped
        if (row['intercropped'] != 1) and (row['plot_fullyCrop'] == 1):
            return 1



panel_pd['plot_cropFrac'] = panel_pd.apply( lambda row: clean_plot_cropFrac(row), axis=1)
panel_pd['plot_cropFrac'].value_counts()



### clean perennial cropnames
####################################################################################################################
####################################################################################################################

perennialCropnameConvert_dct = {
'" cassava plot"': 'cassava',
'"acacia "': 'acacia',
'"avocado "': 'avocado',
'"avocado crop "': 'avocado',
'"avocado pears "': 'avocado',
'"banana "': 'banana',
'"banana plot "': 'banana',
'"bananas "': 'banana',
'"cassava "': 'cassava',
'"cassava mbundumale "': 'cassava',
'"cassava plot "': 'cassava',
'"coffee "': 'coffee',
'"english maize "': 'maize',
'"guava "': 'guava',
'"guava tree "': 'guava',
'"guava trees "': 'guava',
'"halale banana "': 'banana',
'"kenya banana "': 'banana',
'"kombezi cassava "': 'cassava',
'"lemon tree "': 'lemon',
'"lemons "': 'lemon',
'"mango "': 'mango',
'"mango plot "': 'mango',
'"mango trees "': 'mango',
'"mangoe "': 'mango',
'"matubeni or mulberry "': 'mulberry',
'"mkombezi cassava "': 'cassava',
'"mulberries "': 'mulberry',
'"nkondezi cassava "': 'cassava',
'"orange "': 'orange',
'"pawpaw "': 'pawpaw',
'"pawpaw tree "': 'pawpaw',
'"sauti cassava "': 'cassava',
'"t0 guava plot "': 'guava',
'"t01 avocado plot "': 'avocado',
'"t01 avocados plot "': 'avocado',
'"t01 cassava plot "': 'cassava',
'"t01 mango plot "': 'mango',
'"tangerine "': 'tangerine',
'"tangerine plot "': 'tangerine',
'"thupula cassava "': 'cassava',
'"custade apple "': 'custard apple',
'"mexican apple "': 'mexican apple',
# '""" cassava plot"""': 'cassava',
# '"""acacia """': 'acacia',
# '"""avocado """': 'avocado',
# '"""avocado crop """': 'avocado',
# '"""avocado pears """': 'avocado',
# '"""banana """': 'banana',
# '"""banana plot """': 'banana',
# '"""bananas """': 'banana',
# '"""cassava """': 'cassava',
# '"""cassava mbundumale """': 'cassava',
# '"""cassava plot """': 'cassava',
# '"""coffee """': 'coffee',
# '"""english maize """': 'maize',
# '"""guava """': 'guava',
# '"""guava tree """': 'guava',
# '"""guava trees """': 'guava',
# '"""halale banana """': 'banana',
# '"""kenya banana """': 'banana',
# '"""kombezi cassava """': 'cassava',
# '"""lemon tree """': 'lemon',
# '"""lemons """': 'lemon',
# '"""mango """': 'mango',
# '"""mango plot """': 'mango',
# '"""mango trees """': 'mango',
# '"""mangoe """': 'mango',
# '"""matubeni or mulberry """': 'mulberry',
# '"""mkombezi cassava """': 'cassava',
# '"""mulberries """': 'mulberry',
# '"""nkondezi cassava """': 'cassava',
# '"""orange """': 'orange',
# '"""pawpaw """': 'pawpaw',
# '"""pawpaw tree """': 'pawpaw',
# '"""sauti cassava """': 'cassava',
# '"""t0 guava plot """': 'guava',
# '"""t01 avocado plot """': 'avocado',
# '"""t01 avocados plot """': 'avocado',
# '"""t01 cassava plot """': 'cassava',
# '"""t01 mango plot """': 'mango',
# '"""tangerine """': 'tangerine',
# '"""tangerine plot """': 'tangerine',
# '"""thupula cassava """': 'cassava',
# '"""custade apple """': 'custard apple',
# '"""mexican apple """': 'mexican apple',
'1 mango tree': 'mango',
'20:20 cassava': 'cassava',
'aavocado': 'avocado',
'acacia': 'acacia',
'acacia and ntawa': 'acacia',
'acacia kachere': 'acacia',
'acacia tree': 'acacia',
'acacia trees': 'acacia',
'acacias': 'acacia',
'acassia': 'acacia',
'accacia': 'acacia',
'accacias': 'acacia',
'acecia': 'acacia',
'aceicia': 'acacia',
'acocado': 'avocado',
'alcacia': 'acacia',
'alcasia': 'acacia',
'albizia lebeck': 'albizia lebbeck',
'alexia lebeck': 'albizia lebbeck',
"apple's": 'apple',
'apples': 'apple',
'avacodo peas': 'avacodo',
'avocado': 'avacodo',
'avocado  pears': 'avacodo',
'avocado pair': 'avacodo',
'avocado pea': 'avacodo',
'avocado pea plot': 'avacodo',
'avocado pear': 'avacodo',
'avocado pears': 'avacodo',
'avocado peas': 'avacodo',
'avocado peya': 'avacodo',
'avocado t02': 'avacodo',
'avocado tree': 'avacodo',
'avocado trees': 'avacodo',
'avocadons': 'avacodo',
'avocados': 'avacodo',
'avocando': 'avacodo',
'avodaco': 'avacodo',
'avogadro': 'avacodo',
'avovado peas': 'avacodo',
'bamboon': 'bamboo',
'banan': 'banana',
'banana fruit': 'banana',
'banana fruits': 'banana',
'banana plantains': 'plantain',
'banana plot': 'banana',
'banana tree': 'banana',
"banana's": 'banana',
'bananaa': 'banana',
'bananas': 'banana',
'bananas plot': 'banana',
'bananna': 'banana',
'bannana': 'banana',
'baobab trees': 'baobab',
'blue gam': 'blue gum',
'bluegam': 'blue gum',
'bluegum': 'blue gum',
'blugam': 'blue gum',
'bluguem': 'blue gum',
'blugum': 'blue gum',
'boaboa': 'baobab',
'brugum': 'blue gum',
'casaava': 'cassava',
'casasava': 'cassava',
'casava': 'cassava',
'casava plot': 'cassava',
'cassav': 'cassava',
'cassava': 'cassava',
'cassava bitilisi': 'cassava',
'cassava bwendu': 'cassava',
'cassava crop': 'cassava',
'cassava garden': 'cassava',
'cassava maize plot': 'cassava',
'cassava plot': 'cassava',
'cassava plot t01': 'cassava',
'cassava plot tg01t01': 'cassava',
'cassava t01': 'cassava',
'cassava tree': 'cassava',
'cassava_plot': 'cassava',
'cassavaplot': 'cassava',
'casssava': 'cassava',
'chammwamba': 'moringa',
'chammwamba tree': 'moringa',
'chinese cabbage': 'cabbage',
'd01 mango plot': 'mango',
'english maize': 'maize',
'eucalyptus': 'blue gum',
'eucalyptus globus': 'blue gum',
'eucalyptus globus(bluegum)': 'blue gum',
'finger millet': 'millet',
'fuel trees': 'fuel wood trees',
'fuel wood tree': 'fuel wood trees',
'gauva': 'guava',
'gesha coffee': 'coffee',
'guarva': 'guava',
'guava t03': 'guava',
'guava tree': 'guava',
'guava trees': 'guava',
'guava, magagadeya and mizimbe': 'guava',
'guavant': 'guava',
'guavas': 'guava',
'guave': 'guava',
'guaves': 'guava',
'gwuava': 'guava',
'halale banana': 'banana',
'india banana': 'banana',
'ld01 guava pakhomo': 'guava',
'lembwendu cassava': 'cassava',
'lemon tree': 'lemon',
'lemon trees': 'lemon',
'lemons': 'lemon',
'local mangoes': 'mango',
'macadamia nut': 'macadamia',
'macademia nuts': 'macadamia',
'magoe': 'mango',
'mamgo': 'mango',
'mamgoes': 'mango',
'mango  trees': 'mango',
'mango (maboloma)': 'mango',
'mango es': 'mango',
'mango fruit': 'mango',
'mango kalisela': 'mango',
'mango maboloma': 'mango',
'mango plot': 'mango',
'mango plot ld01t01': 'mango',
'mango tree': 'mango',
'mango trees': 'mango',
'mango tress': 'mango',
'mango, naartjes': 'mango',
'mango.': 'mango',
'mangoe': 'mango',
'mangoe trees': 'mango',
'mangoe trees plot': 'mango',
'mangoeplot': 'mango',
'mangoes': 'mango',
'mangoes (5)': 'mango',
'mangoes garden': 'mango',
'mangoes tree': 'mango',
'mangoes trees': 'mango',
'mangoes,': 'mango',
'mangot01': 'mango',
'mangotree': 'mango',
'mauringa(chammwamba)': 'moringa',
'mbundumale cassava': 'cassava',
'mkombezi cassava': 'cassava',
'mkondezi cassava': 'cassava',
'mmango': 'mango',
'mngo': 'mango',
'mongoe trees': 'mango',
'mongoes': 'mango',
'moringa(chammwamba)': 'moringa',
'mpapa cassava': 'cassava',
'mtutumusi cassava': 'cassava',
'mulberries': 'mulberry',
'munda wa coffee': 'coffee',
'naartje': 'tangerine',
'naartje (tangerine)': 'tangerine',
'naartjes': 'tangerine',
'"naartjes "': 'tangerine',
'orange trees': 'orange',
'orange trees plot': 'orange',
'orangenuts': 'orange',
'oranges': 'orange',
'palm': 'oil palm',
'palm fruit': 'oil palm',
'palm oil tree': 'oil palm',
'palm trees': 'oil palm',
'papaaya': 'papaya',
'papaw': 'papaya',
'papaya plot': 'papaya',
'papaya tree': 'papaya',
"papaya's": 'papaya',
'papayas': 'papaya',
'paw  paw': 'papaya',
'paw paw': 'papaya',
'paw paw plot': 'papaya',
'pawapaw': 'papaya',
'pawpaw': 'papaya',
'pawpaw (papaya)': 'papaya',
'pawpaw /papaya': 'papaya',
'pawpaw plot': 'papaya',
'pawpaw tree': 'papaya',
'pawpaw trees': 'papaya',
'pawpaw. tree': 'papaya',
'pawpaw/papaya': 'papaya',
'pawpaws': 'papaya',
'payaya': 'papaya',
'peach crop': 'peach',
'peach tree': 'peach',
'peaches': 'peach',
'peaches tree': 'peach',
'pearl millet': 'millet',
'pears': 'pear',
'peas': 'pea',
'pinaaples': 'pineapple',
'pine apple': 'pineapple',
'pineapples': 'pineapple',
'plums': 'plum',
'r01 cassava plot': 'cassava',
'r01 mango': 'mango',
'r01 mango plot': 'mango',
'research cassava': 'cassava',
'rockot': 'rocket',
'sauti  cassava': 'cassava',
'sauti cassava': 'cassava',
'sauti cassava jnk': 'cassava',
'soya': 'soybean',
'soyabean': 'soybean',
'sugarcame': 'sugarcane',
'sugarcane plot': 'sugarcane',
'sugarcanes': 'sugarcane',
'sugercane': 'sugarcane',
'sungarcane': 'sugarcane',
't01  tea': 'tea',
't01 acacia': 'acacia',
't01 acacia land dwelling': 'acacia',
't01 avocado': 'avocado',
't01 avocado plot': 'avocado',
't01 banana': 'banana',
't01 banana plot': 'banana',
't01 banana tree': 'banana',
't01 bananas': 'banana',
't01 bladful cassava plot': 'cassava',
't01 bluegam': 'blue gum',
't01 bluegum': 'blue gum',
't01 bluegum plot': 'blue gum',
't01 buladifulu cassava plot for tg03': 'cassava',
't01 cassav': 'cassava',
't01 cassava': 'cassava',
't01 cassava plot': 'cassava',
't01 chavwanga cassava plot for tg01': 'cassava',
't01 fruits': 'fruits',
't01 gomani cassava plot': 'cassava',
't01 guava': 'guava',
't01 guava plot': 'guava',
't01 guavas': 'guava',
't01 lemon plot': 'lemon',
't01 mango': 'mango',
't01 mango  plot': 'mango',
't01 mango plot': 'mango',
't01 mango tree': 'mango',
't01 mangoes': 'mango',
't01 orange': 'orange',
't01 papaya': 'papaya',
't01 pawpaw': 'papaya',
't01 peaches': 'peach',
't01 sugarcane': 'sugarcane',
't01 sugarcane plot': 'sugarcane',
't01 tangerines': 'tangerine',
't01 tea plot': 'tea',
't01 tea.': 'tea',
't01-coffee': 'coffee',
't01-mango': 'mango',
't01_avocado trees': 'avocado',
't01_mango': 'mango',
't01banana': 'banana',
't01cassava plot': 'cassava',
't01mango': 'mango',
't01masungazungu cassava plot': 'cassava',
't02 apple plot': 'apple',
't02 avocado': 'avocado',
't02 avocado plot': 'avocado',
't02 banana': 'banana',
't02 bluegam': 'blue gum',
't02 cassava': 'cassava',
't02 cassava plot': 'cassava',
't02 glicidia': 'gliricidia',
't02 guava': 'guava',
't02 guava plot': 'guava',
't02 lemon plot': 'lemon',
't02 mango': 'mango',
't02 mango plot': 'mango',
't02 orange': 'orange',
't02 orange  plot': 'orange',
't02 papaya trees': 'papaya',
't02 paw paw': 'papaya',
't02 pawpaw': 'papaya',
't02 pawpaw plot': 'papaya',
't02 peaches': 'peach',
't02 sugarcane': 'sugarcane',
't02banana plot': 'banana',
't03 avocado': 'avocado',
't03 avocado pea': 'avocado',
't03 avocado plot': 'avocado',
't03 banana': 'banana',
't03 bluegum': 'blue gum',
't03 cassava': 'cassava',
't03 guava': 'guava',
't03 guava plot': 'guava',
't03 mango': 'mango',
't03 oranges': 'orange',
't03 pawpaw': 'papaya',
't03 pitches plot': 'peach',
't04 banana': 'banana',
't04 guava': 'guava',
't04 orange tree': 'orange',
't05 peaches': 'peach',
'tangalines tree': 'tangerine',
'tangarine': 'tangerine',
'tangerine  plot': 'tangerine',
'tangerine  trees': 'tangerine',
'tangerine trees': 'tangerine',
'tangerines': 'tangerine',
'tanjaren': 'tangerine',
'tanjerines': 'tangerine',
'tea trees': 'tea',
'tomato fruit': 'tomato',
'vocado': 'avocado',
'zambia banana': 'banana',
'zanzabar banana': 'banana',
'kaluma banana': 'banana',
'mangp': 'mango',
'piches': 'peach',
'pichesi': 'peach',
'pichesi trees': 'peach',
'powpow': 'papaya',
'custade apple] poza': 'custard apple',
'[custade apple] poza': 'custard apple',
'castade apple': 'custard apple',
'custade apple': 'custard apple',
'custard apple': 'custard apple',
'custard apple tree(poza)': 'custard apple',
'custarde apple': 'custard apple',
'custered apple': 'custard apple',
'poza (custade apple)': 'custard apple',
'masuku': 'mexican apple',
'"masuku "': 'mexican apple',
'masuku (mexican apple)': 'mexican apple',
'masuku mexican apple': 'mexican apple',
'masuku tree': 'mexican apple',
'masuku trees': 'mexican apple',
'masuku,': 'mexican apple',
'maxican apple': 'mexican apple',
'maxicane apple': 'mexican apple',
'mexan apple': 'mexican apple',
'mexcan apple': 'mexican apple',
'mexican aple': 'mexican apple',
'mexican apple': 'mexican apple',
'mexican apple (masuku)': 'mexican apple',
'mexican apple [masuku]': 'mexican apple',
'mexican apple masuku': 'mexican apple',
'mexican apples': 'mexican apple',
    }


cropNamesNaN_lst = [
    '"""r01 """',
    '1',
    '1 50 kg bag',
    '1 acre',
    '1 pail',
    '10',
    '100',
    '12',
    '15',
    '19',
    '2',
    '2 pail',
    '3',
    '30',
    '3020580209ld01pakhomor01chimanga',
    '3381',
    '35',
    '350',
    '39',
    '4',
    '40',
    '5',
    '5 pail',
    '50 kg',
    '6',
    '7',
    '8',
    '9',
    '9999',
    'one 50 kg bag',
    'r01',
    'rg01t01',
    't01',
    't02',
    't04',
    'to 1',
    'to1',
    ]

# harmonise perennial crop names
panel_pd['crop'] = panel_pd['crop'].replace(perennialCropnameConvert_dct)

# overwrite unreasonable cropnames as NaN
panel_pd.loc[
    panel_pd['crop'].isin(cropNamesNaN_lst),
    'crop'
] = np.nan

# inspect final crop names
print(panel_pd['crop'].value_counts().to_string())


### tidy-up
####################################################################################################################
####################################################################################################################


## clean & harmonize region name (ADM unit level 1)
panel_pd['region'].value_counts()

panel_pd['region'].replace({
    'north': 'northern',
    'south': 'southern',
    }, inplace = True)


## clean & harmonize district names (ADM unit level 2)
panel_pd['district'].value_counts().sort_index()

panel_pd['district'].replace({
    # 'blantyre city': 'blantyre',
    'blanytyre': 'blantyre',
    # 'lilongwe city': 'lilongwe',
    # 'mzuzu city': 'mzimba',
    'nkhatabay': 'nkhata bay',
    'nkhota kota': 'nkhotakota',
    # 'zomba city': 'zomba',
    'zomba non-city': 'zomba',
    }, inplace = True)



len(panel_pd['district'].drop_duplicates())
panel_pd['district'].value_counts().sort_index()

# get list of column-names
colNames_lst = panel_pd.columns.to_list()


########## drop redundant variables
##########################################################
panel_pd.drop([
    'cropCode',
    'plot_fullyCrop',
    'lastMajor_hhCultOwn_dum',
    'lastMinor_hhCultOwn_dum',
    'cropCode_detailed',
    'plot_cropFrac_secondary',
    'majorSeason_dum',
    'intercropped',    
    'cropStand',    
    ], axis=1, inplace=True)



	



########## optional: subset & reorder columns
##########################################################
panel_pd.columns.to_list()

cols_ordered = [
'wave',
'hh_ID',
'GS_yearStart',
'season',
'field_ID',
'plot_ID',
'crop',
'lon',
'lat',
'plot_cropFrac',
'areaPlotGPS_ha',
'areaPlotReported_ha',
'areaPlotReported',
'areaPlotReported_unit',
'seeding_month',
'seeding_year',
'harvestStart_month',
'harvestEnd_month',
'harvestStart_year',
'harvestEnd_year',
'ea_ID',
'region',
'district',
'tradAuthority_ID',
'district_tradAuthority_mix',
'dataset_name',
'dataset_doi',
 ]

panel_pd = panel_pd[cols_ordered]





########## save panel to disk
##########################################################
panel_pd.to_csv( Path( str(project_path), 'scripts', 'LSMS_MWI_ingested', 'MWI_panel_cleaned.csv' ), index=False )



