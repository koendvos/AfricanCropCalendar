#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Apr 27 12:44:24 2022

@author: ugrewer

Ingest household survey data from the Malawi LSMS
"""


### package imports
##########################################################
import os
import socket
import sys
from pathlib import Path


import numpy as np
import pandas as pd




### setup
####################################################################################################################
####################################################################################################################

# # identify user (platform-independent)
# getpass.getuser()
# # identify home-directory (platform-independent)
# os.path.expanduser("~")

# print all environmental variables
for envVar_name, envVar_path in os.environ.items():
    print(envVar_name, envVar_path)


### access project folder path (from environmental variable)
project_path = os.environ['LSMS_cropSeasons_env']


# # add project directory to system path (note: system path expects only strings to be added - not pathlib_objects)
# if str(project_path) not in sys.path:
#     sys.path.append( str(project_path) )

# set working directory to project path
os.chdir(project_path)

# import major path locations
from defPaths import *





### define dataset structure
####################################################################################################################
####################################################################################################################


class Panel:
    ''' Country-level panel dataset. '''

    def __init__(self, country, wave_lst, panel_indexVars_lst, cropNameConvert_dct):

        self.country = country
        self.wave_lst = wave_lst
        self.panel_indexVars_lst = panel_indexVars_lst
        self.cropNameConvert_dct = cropNameConvert_dct
        self.cropsRef_lst = [
          'sugarcane',
          'sunflower',
          'beans',
          'tomato',
          'peas',
          'groundnut',
          'onion',
          'cotton',
          'sweet potato',
          'tobacco',
          'sorghum',
          'maize',
          'soyabean',
          'paprika',
          'cabbage',
          'rice',
          'other',
          'irish potato',
          'okra',
          'ground bean',
          'chinese cabbage',
          'finger millet',
          'pigeonpea',
          'pumpkin leaves',
          'pearl millet',
          'rapeseed',
          'coconut',
          'cowpeas',
          'mustard',
          'leafy greens',
          'eggplant',
          'cassava',
          'lettuce',
          'cucumber',
          'sourgram(mapila)',
          'butter beans',
          'yam',
          'pawpaw',
          'watermelon',
          'velvet beans',
          'mango',
          'pumpkin',
          'lablab',
          'sesame',
          'spinach',
          'wheat',
          'coco yam',
          'chickpeas',
          'broccoli',
          'hemp',
          'carrots',
          'cocoa',
]



class SurveyWave(Panel):
    ''' Single survey wave for a given country. '''

    def __init__(self, country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, wave, wave_csvFolder, dataset_name, dataset_doi, modVar_dct, cropNameHarmonize_dct):

        ### inherinting __init__ from Panel
        #######
        Panel.__init__(self, country, wave_lst, panel_indexVars_lst, cropNameConvert_dct)

        ### extending __init__
        #######
        self.wave = wave
        self.wave_csvFolder = wave_csvFolder
        
        self.dataset_name = dataset_name
        self.dataset_doi = dataset_doi
        
        self.modVar_dct = modVar_dct
        self.cropNameHarmonize_dct = cropNameHarmonize_dct

        # list of modules selected for ingestion
        self.modlue_lst = list( self.modVar_dct.keys() )

        # tuple of index-variable-lists
        self.indexVars_tpl = self.get_indexVars_tpl()


    ### methods
    #######

    def get_indexVars_tpl(self):
        ''' Create tuple of index-variable lists used across all modules in this wave. '''

        # generate list of index-variable-lists
        indexVarLst_lst = list()

        # loop over modules
        for module in self.modVar_dct.keys():

            # grow list of index-variable lists
            if pd.isna( self.modVar_dct[module]['season'] ):
                indexVarLst_lst.append( list(self.modVar_dct[module]['indexVars'].keys()) )
            else:
                indexVarLst_lst.append( list(self.modVar_dct[module]['indexVars'].keys()) + ['season'] )

        # remove duplicate entries (convert "list of lists" to "set of lists")
        indexVarLst_set = set(tuple(x) for x in indexVarLst_lst)

        # convert set to tuple
        indexVars_tpl = tuple( indexVarLst_set )

        return indexVars_tpl





class Module(SurveyWave):
    ''' Single questionnaire module from a specific survey wave of a given country. '''

    def __init__(self, country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, wave, wave_csvFolder, dataset_name, dataset_doi, modVar_dct, cropNameHarmonize_dct, module_name):

        ### inherinting __init__ from SurveyWave
        #######
        SurveyWave.__init__(self, country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, wave, wave_csvFolder, dataset_name, dataset_doi, modVar_dct, cropNameHarmonize_dct)

        ### extending __init__
        #######

        # module name
        self.module_name = module_name

        # module variables (selected for ingestion), (using raw /original variable-names)
        self.var_lst = self.get_var_lst()

        # module index variables (using renamed variable-names)
        self.indexVar_lst = self.get_indexVar_lst()

        # module season
        self.season = self.modVar_dct[self.module_name]['season']

        # module-dataframe
        self.module_pd = self.get_module_pd()


    ### methods
    #######

    def get_var_lst(self):
        ''' Get list of all variables in module.'''

        # create list of all index- and data-variables (using raw /original variable-names)
        module_varLst = list( self.modVar_dct[self.module_name]['indexVars'].values() ) + list( self.modVar_dct[self.module_name]['dataVars'].values() )
        # drop NaN
        module_varLst = [x for x in module_varLst if pd.isnull(x) == False]

        return module_varLst


    def get_indexVar_lst(self):
        ''' Get list of index-variables for this module.'''

        # access all index variables recorded in dictionary
        indexVar_lst = list( self.modVar_dct[self.module_name]['indexVars'].keys() )

        # add "season" as index-variable (if applicable)
        if not pd.isna( self.modVar_dct[self.module_name]['season'] ):
            indexVar_lst.append('season')

        return indexVar_lst


    def get_module_pd(self):
        ''' Get dataframe of module. '''


        ### load module into pandas
        module_pd = pd.read_csv( Path( str(self.wave_csvFolder), f'{self.module_name}.csv' ), encoding = "ISO-8859-1" )

        ### convert all coumn names to lower-case
        module_pd.columns = map(str.lower, module_pd.columns)

        ### subset to target columns
        # print('*** The columns in the raw dataframe are: \n', module_pd.columns.to_list())
        module_pd = module_pd[self.var_lst]

        ### rename index variables
        indexVarsDct_revert = {v: k for k, v in self.modVar_dct[self.module_name]['indexVars'].items()}
        module_pd.rename( indexVarsDct_revert, axis=1, inplace=True)
        ### rename data variables
        dataVarsDct_revert = {v: k for k, v in self.modVar_dct[self.module_name]['dataVars'].items()}
        module_pd.rename( dataVarsDct_revert, axis=1, inplace=True)

        ### add season-column (if applicable)
        if not pd.isna( self.modVar_dct[self.module_name]['season'] ):
            module_pd['season'] = self.modVar_dct[self.module_name]['season']

        ### add wave-column
        module_pd['wave'] = self.wave


        ### harmonize crop names

        # filter: consider only modules where crop is index variable (i.e. crop-level modules)
        if 'crop' in self.modVar_dct[self.module_name]['indexVars'].keys():

            # access list of crop-columns for this module
            cropCols_lst = self.cropNameHarmonize_dct[self.module_name]['cropCols_lst']

            # rename all crop-names to lower case (& strip eventual white spaces)
            for cropCol in cropCols_lst:
                
                # print('\ncropCol is:', cropCol)
                module_pd[cropCol] = module_pd.apply( lambda row: row[cropCol].lower().strip() if isinstance(row[cropCol], str) else row[cropCol], axis=1)
                # module_pd[cropCol] = module_pd[cropCol].str.lower().str.strip()

            # rename crops in all crop-columns
            for cropCol in cropCols_lst:
                module_pd[cropCol].replace( self.cropNameConvert_dct, inplace=True )

            # identify main crop on plot
            module_pd['crop'] = module_pd[self.cropNameHarmonize_dct[self.module_name]['mainCropCol']].copy()

        return module_pd









### define panel & survey-waves
####################################################################################################################
####################################################################################################################


### define country
country = 'MWI'


### define survey waves
wave_lst = [2010, 2013, 2016, 2019]
# wave_lst = [2004, 2010, 2013, 2016, 2019]


### define index variables of panel
panel_indexVars_lst = ['wave', 'season', 'hh_ID', 'field_ID', 'plot_ID', 'crop']




##### define module-variable dictionary: 2010 wave
####################

modVar_dct_2010 = {
    
    'householdgeovariables': { 'indexVars': {'hh_ID': 'case_id',
                                'wave': np.NaN,
                                  },
                    'dataVars': {'lon': 'lon_modified',
                                  'lat': 'lat_modified',
                                  },
                    'season': np.NaN,
    },


    'hh_mod_a_filt': { 'indexVars': { 'hh_ID': 'case_id',
                            'wave': np.NaN,
                              },
                    'dataVars': {
                                'region': np.NaN,
                                'district': 'hh_a01',
                                'ea_ID': 'ea_id',
                                'tradAuthority_ID': 'hh_a02',
                                'district_tradAuthority_mix': 'hh_a02b',
                                  },
                    'season': np.NaN,
    },


    
    'hh_mod_x': { 'indexVars': {'hh_ID': 'case_id',
                                'wave': np.NaN,
                                  },
                    'dataVars': {'lastMajor': 'hh_x02', # answers -> 1: 2009/10; 2: 2008/09
                                  'lastMajor_hhCultOwn_dum': 'hh_x03', # did you or anyone in your household own or cultivate a plot during the [LAST COM (hh_x03)]
                                  'lastMinor': 'hh_x04', # answers -> 1: 2009; 2: 2010
                                  'lastMinor_hhCultOwn_dum': 'hh_x05',
                                  # 'surveyYear_hhCult_dum': 'hh_x10',
                                  },
                    'season': np.NaN,
    },


    'ag_mod_c': { 'indexVars': { 'hh_ID': 'case_id',
                            'plot_ID': 'ag_c00',
                            'wave': np.NaN,
                              },
                    'dataVars': {
                                 'areaPlotReported': 'ag_c04a',
                                 'areaPlotReported_unit': 'ag_c04b',
                                  'areaPlotGPS': 'ag_c04c',
                                  },
                    'season': 'major',
    },


    # 'ag_mod_d': { 'indexVars': { 'hh_ID': 'case_id',
    #                         'plot_ID': 'ag_d00',
    #                         'crop': np.NaN,
    #                         'wave': np.NaN,
    #                           },
    #                 'dataVars': {'field_usage': 'ag_d14',
    #                             'crop01': 'ag_d20a',
    #                             'crop02': 'ag_d20b',
    #                             'crop03': 'ag_d20c',
    #                             'crop04': 'ag_d20d',
    #                             'crop05': 'ag_d20e',
    #                               },
    #                 'season': 'major',
    # },
    

    'ag_mod_g': { 'indexVars': { 'hh_ID': 'case_id',
                            'plot_ID': 'ag_g0b',
                            'crop': np.NaN,
                            'wave': np.NaN,
                              },
                    'dataVars': {
                                 'hhCultivated_dum': 'ag_g0a',
                                 'cropCode': 'ag_g0d',
                                 'cropCode_other': 'ag_g0d_os',
                                 'cropStand': 'ag_g01',
                                 'plot_fullyCrop': 'ag_g02',
                                 'plot_cropFrac': 'ag_g03',
                                 'seeding_month': 'ag_g05a',
                                 'seeding_year': 'ag_g05b',
#                                 'cropHarvested_dum': 'ag_g07',
                                 'harvestStart_month': 'ag_g12a',
                                 'harvestEnd_month': 'ag_g12b',
                                  },
                    'season': 'major',
    },


    'ag_mod_j': { 'indexVars': { 'hh_ID': 'case_id',
                            'plot_ID': 'ag_j00',
                            'wave': np.NaN,
                              },
                    'dataVars': {'areaPlotReported': 'ag_j05a',
                                 'areaPlotReported_unit': 'ag_j05b',
                                 'areaPlotReported_unitOther': 'ag_j05b_os',
                                 'areaPlotGPS': 'ag_j05c', # in acres
                                  },
                    'season': 'minor',
    },
    

    # 'ag_mod_k': { 'indexVars': { 'hh_ID': 'case_id',
    #                         'plot_ID': 'ag_k0a',
    #                         'crop': np.NaN,
    #                         'wave': np.NaN,
    #                           },
    #                 'dataVars': {
    #                              'field_usage': 'ag_k15',
    #                              'field_usage_other': 'ag_k15_os',
    #                              'crop01': 'ag_k21a',
    #                              'crop01_other': 'ag_k21a_os',
    #                              'crop02': 'ag_k21b',
    #                              'crop02_other': 'ag_k21b_os',
    #                              'crop03': 'ag_k21c',
    #                              'crop03_other': 'ag_k21c_os',
    #                              'crop04': 'ag_k21d',
    #                              'crop04_other': 'ag_k21d_os',
    #                              'crop05': 'ag_k21e',
    #                              'crop05_other': 'ag_k21e_os',
    #                               },
    #                 'season': 'minor',
    # },

    
    'ag_mod_m': { 'indexVars': { 'hh_ID': 'case_id',
                            'plot_ID': 'ag_m0b',
                            'crop': np.NaN,
                            'wave': np.NaN,
                              },
                    'dataVars': {'hhCultivated_dum': 'ag_m0a',
                                 'cropCode': 'ag_m0d',
                                 'cropCode_other': 'ag_m0d_os',
                                 'cropStand': 'ag_m01',
                                 'plot_fullyCrop': 'ag_m02',
                                 'plot_cropFrac': 'ag_m03',
                                 'seeding_month': 'ag_m05a',
                                 'seeding_year': 'ag_m05b',
                                 # 'cropHarvested_dum': 'ag_m07',
                                 'harvestStart_month': 'ag_m12a',
                                 'harvestEnd_month': 'ag_m12b',
                                  },
                    'season': 'minor',
    },
    
}



##### define module-variable dictionary: 2013 wave (from 2010-2013 short-term panel)
####################

modVar_dct_2013 = {

    'householdgeovariables_ihps_13': { 'indexVars': {
                                'hh_ID': 'y2_hhid',
                                'wave': np.NaN,
                                  },
                    'dataVars': {
                                'lon': 'lon_dd_mod',
                                'lat': 'lat_dd_mod',
                                  },
                    'season': np.NaN,
    },


    'hh_mod_a_filt_13': { 'indexVars': { 
                            'hh_ID': 'y2_hhid', # unique hh-identifier used by 2010-2013 short-term panel
                            'wave': np.NaN,
                              },
                    'dataVars': {
                                'hh_ID2': 'case_id', # unique hh-identifier used in IHS3 (also called case_id in IHS3)
                                'hh_ID3': 'hhid',
                                'region': 'region',
                                'district': 'district',
                                'ea_ID': 'ea_id',
                                'tradAuthority_ID': 'hh_a10b',
                                  },
                    'season': np.NaN,
    },

    
    'hh_mod_x_13': { 'indexVars': {'hh_ID': 'y2_hhid',
                                'wave': np.NaN,
                                  },
                    'dataVars': {'lastMajor': np.NaN, # 2012/2013 rainy season
                                  'lastMajor_hhCultOwn_dum': 'hh_x10', # 2012/2013 rainy season
                                  'lastMinor': np.NaN, # 2013 dry season
                                  'lastMinor_hhCultOwn_dum': 'hh_x18', # 2013 dry season
                                  },
                    'season': np.NaN,
    },


    'ag_mod_c_13': { 'indexVars': {'hh_ID': 'y2_hhid',
                                'field_ID': 'ag_c03_2', # "2012/2013 garden id of the garden that the plot is a part of"
                                'plot_ID': 'ag_c00',
                                'wave': np.NaN,
                                  },
                    'dataVars': {'areaPlotReported': 'ag_c04a',
                                  'areaPlotReported_unit': 'ag_c04b', # 1: acre, 2: hectare, 3: sqm, 4: other
                                  'areaPlotGPS': 'ag_c04c', # in acres
                                  },
                    'season': 'major',
    },


    # 'ag_mod_d_13': { 'indexVars': {'hh_ID': 'y2_hhid',
    #                             'plot_ID': 'ag_d00',
    #                             'crop': np.NaN,
    #                             'wave': np.NaN,
    #                               },
    #                 'dataVars': {
    #                     'field_usage': 'ag_d14', # 2012/2013 rainy season
    #                     'crop01': 'ag_d20a', # 2012/2013 rainy season
    #                     'crop02': 'ag_d20b',
    #                     'crop03': 'ag_d20c',
    #                     'crop04': 'ag_d20d',
    #                     'crop05': 'ag_d20e',
    #                     'planting_month': 'ag_d35_1a', # timepoint when planting was finished
    #                     'planting_week': 'ag_d35_1b',
    #                               },
    #                 'season': 'major',
    # },


    'ag_mod_g_13': { 'indexVars': {'hh_ID': 'y2_hhid',
                                'plot_ID': 'ag_g00',
                                'crop': np.NaN,
                                'wave': np.NaN,
                                  },
                    'dataVars': {
                                  'cropCode': 'ag_g0b',
                                  'hhCultivated_dum': 'ag_g0a',
                                  'cropStand': 'ag_g01',
                                  'plot_fullyCrop': 'ag_g02',
                                  'plot_cropFrac': 'ag_g03',
                                  'seeding_month': 'ag_g05a', # 2012/2013 rainy season
                                  'seeding_year': 'ag_g05b', # 2012/2013 rainy season
                                  'harvestStart_month': 'ag_g12a',
                                  'harvestEnd_month': 'ag_g12b',
                                  },
                    'season': 'major',
    },


    'ag_mod_j_13': { 'indexVars': {'hh_ID': 'y2_hhid',
                                'plot_ID': 'ag_j00',
                                'wave': np.NaN,
                                  },
                    'dataVars': {
                                  'areaPlotReported': 'ag_j05a', # 2013 dry season
                                  'areaPlotReported_unit': 'ag_j05b',
                                  'areaPlotGPS': 'ag_j05c',
                                  },
                    'season': 'minor',
    },


    # 'ag_mod_k_13': { 'indexVars': {'hh_ID': 'y2_hhid',
    #                             'plot_ID': 'ag_k00',
    #                             'crop': np.NaN,
    #                             'wave': np.NaN,
    #                               },
    #                 'dataVars': {
    #                             'field_usage': 'ag_k15', # 2013 dry season
    #                             'crop01': 'ag_k21a',
    #                             'crop02': 'ag_k21b',
    #                             'crop03': 'ag_k21c',
    #                             'crop04': 'ag_k21d',
    #                             'crop05': 'ag_k21e',
    #                             'lastMinor_cult': 'ag_k36', # 2013 dry season
    #                             'planting_month': 'ag_k36_1a', # 2013 dry season
    #                             'planting_week': 'ag_k36_1b', # 2013 dry season
    #                               },
    #                 'season': 'minor',
    # },


    'ag_mod_m_13': { 'indexVars': {'hh_ID': 'y2_hhid',
                                'plot_ID': 'ag_m00',
                                'crop': np.NaN,
                                'wave': np.NaN,
                                  },
                    'dataVars': {'hhCultivated_dum': 'ag_m0a',
                                'cropCode': 'ag_m0c',
                                'cropStand': 'ag_m01',
                                'plot_fullyCrop': 'ag_m02',
                                'plot_cropFrac': 'ag_m03',
                                'seeding_month': 'ag_m05a',
                                'seeding_year': 'ag_m05b',
                                'harvestStart_month': 'ag_m12a',
                                'harvestEnd_month': 'ag_m12b',
                                  },
                    'season': 'minor',
    },

}




##### define module-variable dictionary: 2016 wave
####################

modVar_dct_2016 = {
    'householdgeovariablesihs4': { 'indexVars': {'hh_ID': 'case_id',
                                'wave': np.NaN,
                                  },
                    'dataVars': {'lon': 'lon_modified',
                                  'lat': 'lat_modified',
                                  },
                    'season': np.NaN,
    },
    'hh_mod_a_filt': { 'indexVars': { 'hh_ID': 'case_id',
                            'wave': np.NaN,
                              },
                    'dataVars': {
                                'region': 'region',
                                'district': 'district',
                                'ea_ID': 'ea_id',
                                'tradAuthority_ID': 'hh_a02a',
                                  },
                    'season': np.NaN,
    },
    'hh_mod_x': { 'indexVars': {'hh_ID': 'case_id',
                                'wave': np.NaN,
                                  },
                    'dataVars': {'lastMajor': 'hh_x02',
                                  'lastMajor_hhCultOwn_dum': 'hh_x03',
                                  'lastMinor': 'hh_x04',
                                  'lastMinor_hhCultOwn_dum': 'hh_x05',
                                  },
                    'season': np.NaN,
    },
    'ag_mod_c': { 'indexVars': {'hh_ID': 'case_id',
                                'field_ID': 'gardenid',
                                'plot_ID': 'plotid',
                                'wave': np.NaN,
                                  },
                    'dataVars': {'areaPlotReported': 'ag_c04a',
                                  'areaPlotReported_unit': 'ag_c04b',
                                  'areaPlotGPS': 'ag_c04c',
                                  },
                    'season': 'major',
    },


    # 'ag_mod_d': { 'indexVars': {'hh_ID': 'case_id',
    #                             'field_ID': 'gardenid',
    #                             'plot_ID': 'plotid',
    #                             'crop': np.NaN,
    #                             'wave': np.NaN,
    #                               },
    #                 'dataVars': {
    #                     'field_usage': 'ag_d14',
    #                     'crop01': 'ag_d20a',
    #                     'crop02': 'ag_d20b',
    #                     'crop03': 'ag_d20c',
    #                     'crop04': 'ag_d20d',
    #                     'crop05': 'ag_d20e',
    #                     # 'irrigation_type': 'ag_d28a',
    #                     'planting_month': 'ag_d35_1a',
    #                     'planting_monthHalf': 'ag_d35_1b',
    #                               },
    #                 'season': 'major',
    # },


    'ag_mod_g': { 'indexVars': {'hh_ID': 'case_id',
                                'field_ID': 'gardenid',
                                'plot_ID': 'plotid',
                                'crop': np.NaN,
                                'wave': np.NaN,
                                  },
                    'dataVars': {'cropCode_detailed': 'crop_code',
                                  'cropCode': 'crop_code_collapsed',
                                  'hhCultivated_dum': 'ag_g0a',
                                  # 'variety': 'primary_variety',
                                  # 'variety_improved': 'ag_g0f',
                                  'cropStand': 'ag_g01',
                                  'plot_fullyCrop': 'ag_g02',
                                  'plot_cropFrac': 'ag_g03',
                                  'seeding_month': 'ag_g05a',
                                  'seeding_year': 'ag_g05b',
                                  'harvestStart_month': 'ag_g12a',
                                  'harvestEnd_month': 'ag_g12b',
                                  },
                    'season': 'major',
    },
    'ag_mod_j': { 'indexVars': {'hh_ID': 'case_id',
                                'field_ID': 'gardenid',
                                'plot_ID': 'plotid',
                                'wave': np.NaN,
                                  },
                    'dataVars': {
                                  # 'field_ID_major_dum': 'ag_j04_1',
                                  # 'field_ID_major': 'ag_j04_2a',
                                  # 'field_ID_minor': 'ag_j04_2b',
                                  'areaPlotReported': 'ag_j05a',
                                  'areaPlotReported_unit': 'ag_j05b',
                                  'areaPlotReported_unitOther': 'ag_j05b_oth',
                                  'areaPlotGPS': 'ag_j05c',
                                  },
                    'season': 'minor',
    },


    # 'ag_mod_k': { 'indexVars': {'hh_ID': 'case_id',
    #                             'field_ID': 'gardenid',
    #                             'plot_ID': 'plotid',
    #                             'crop': np.NaN,
    #                             'wave': np.NaN,
    #                               },
    #                 'dataVars': {
    #                             # 'field_ID_major_dum': 'ag_k01',
    #                             # 'field_ID_major': 'ag_k01b',
    #                             'crop01': 'ag_k21a',
    #                             'crop02': 'ag_k21b',
    #                             'crop03': 'ag_k21c',
    #                             'crop04': 'ag_k21d',
    #                             'crop05': 'ag_k21e',
    #                             'crop_other': 'ag_k21_oth',
    #                             'lastMinor_cult': 'ag_k36',
    #                             'planting_month': 'ag_k36_1a',
    #                             'planting_monthHalf': 'ag_k36_1b',
    #                               },
    #                 'season': 'minor',
    # },


    'ag_mod_m': { 'indexVars': {'hh_ID': 'case_id',
                                'field_ID': 'gardenid',
                                'plot_ID': 'plotid',
                                'crop': np.NaN,
                                'wave': np.NaN,
                                  },
                    'dataVars': {'hhCultivated_dum': 'ag_m0a',
                                'cropCode': 'crop_code',
                                # 'variety': 'ag_m0e',
                                # 'varietyOther': 'ag_m0e_oth',
                                # 'variety_localCompositeHybrid': 'ag_m0f',
                                'cropStand': 'ag_m01',
                                'plot_fullyCrop': 'ag_m02',
                                'plot_cropFrac': 'ag_m03',
                                'plot_cropFrac_secondary': 'ag_m05_1',
                                'seeding_month': 'ag_m05a',
                                'seeding_year': 'ag_m05b',
                                'harvestStart_month': 'ag_m12a',
                                'harvestEnd_month': 'ag_m12b',
                                  },
                    'season': 'minor',
    },
}





##### define module-variable dictionary: 2019 wave
####################

modVar_dct_2019 = {
    'householdgeovariables_ihs5': { 'indexVars': {'hh_ID': 'case_id',
                                'wave': np.NaN,
                                  },
                    'dataVars': {'lon': 'ea_lon_mod',
                                  'lat': 'ea_lat_mod',
                                  },
                    'season': np.NaN,
    },
    'hh_mod_a_filt': { 'indexVars': { 'hh_ID': 'case_id',
                            'wave': np.NaN,
                              },
                    'dataVars': {
                                'region': 'region',
                                'district': 'district',
                                'ea_ID': 'ea_id',
                                'tradAuthority_ID': 'hh_a02a',
                                  },
                    'season': np.NaN,
    },
    'hh_mod_x': { 'indexVars': {'hh_ID': 'case_id',
                                'wave': np.NaN,
                                  },
                    'dataVars': {'lastMajor': 'hh_x02',
                                  'lastMajor_hhCultOwn_dum': 'hh_x03',
                                  'lastMinor': 'hh_x04',
                                  'lastMinor_hhCultOwn_dum': 'hh_x05',
                                  },
                    'season': np.NaN,
    },
    'ag_mod_c': { 'indexVars': {'hh_ID': 'case_id',
                                'field_ID': 'gardenid',
                                'plot_ID': 'plotid',
                                'wave': np.NaN,
                                  },
                    'dataVars': {'areaPlotReported': 'ag_c04a',
                                  'areaPlotReported_unit': 'ag_c04b',
                                  'areaPlotGPS': 'ag_c04c',
                                  },
                    'season': 'major',
    },
    # 'ag_mod_d_modified': { 'indexVars': {'hh_ID': 'case_id',
    #                             'field_ID': 'gardenid',
    #                             'plot_ID': 'plotid',
    #                             'crop': np.NaN,
    #                             'wave': np.NaN,
    #                               },
    #                 'dataVars': {'field_usage': 'ag_d14',
    #                             'crop01': 'ag_d20a',
    #                             'crop02': 'ag_d20b',
    #                             'crop03': 'ag_d20c',
    #                             'crop04': 'ag_d20d',
    #                             'crop05': 'ag_d20e',
    #                             'crop_other01': 'ag_d20_oth',
    #                             'crop_other02': 'ag_d20b_oth',
    #                             'planting_month': 'ag_d35_1a',
    #                             'planting_monthHalf': 'ag_d35_1b',
    #                               },
    #                 'season': 'major',
    # },
    'ag_mod_g': { 'indexVars': {'hh_ID': 'case_id',
                                'field_ID': 'gardenid',
                                'plot_ID': 'plotid',
                                'crop': np.NaN,
                                'wave': np.NaN,
                                  },
                    'dataVars': {'cropCode': 'crop_code',
                                  'hhCultivated_dum': 'ag_g0a',
                                  # 'variety': 'ag_g0e_1',
                                  # 'varietyOther': 'ag_g0e_1_oth',
                                  # 'variety_improved': 'ag_g0f',
                                  'cropStand': 'ag_g01',
                                  'plot_fullyCrop': 'ag_g02',
                                  'plot_cropFrac': 'ag_g03',
                                  'seeding_month': 'ag_g05a',
                                  'seeding_year': 'ag_g05b',
                                  'plot_cropPerc': 'ag_g11_2',
                                  'harvestStart_month': 'ag_g12a',
                                  'harvestEnd_month': 'ag_g12b',
                                  },
                    'season': 'major',
    },
    'ag_mod_j': { 'indexVars': {'hh_ID': 'case_id',
                                'field_ID': 'gardenid',
                                'plot_ID': 'plotid',
                                'wave': np.NaN,
                                  },
                    'dataVars': {
                                  # 'field_ID_major_dum': 'ag_j04_1',
                                  # 'field_ID_major': 'ag_j04_2a',
                                  # 'field_ID_minor': 'ag_j04_2b',
                                  'areaPlotReported': 'ag_j05a',
                                  'areaPlotReported_unit': 'ag_j05b',
                                  'areaPlotReported_unitOther': 'ag_j05b_oth',
                                  },
                    'season': 'minor',
    },
    # 'ag_mod_k': { 'indexVars': {'hh_ID': 'case_id',
    #                             'field_ID': 'gardenid',
    #                             'plot_ID': 'plotid',
    #                             'crop': np.NaN,
    #                             'wave': np.NaN,
    #                               },
    #                 'dataVars': {
    #                             # 'field_ID_major_dum': 'ag_k01a',
    #                             # 'field_ID_major': 'ag_k01b',
    #                             'crop01': 'ag_k21a',
    #                             'crop02': 'ag_k21b',
    #                             'crop03': 'ag_k21c',
    #                             'crop04': 'ag_k21d',
    #                             'crop05': 'ag_k21e',
    #                             'crop_other01': 'ag_k21_oth',
    #                             'crop_other02': 'ag_k21b_oth',
    #                             'lastMinor_cult': 'ag_k36',
    #                             'planting_month': 'ag_k36_1a',
    #                             'planting_monthHalf': 'ag_k36_1b',
    #                               },
    #                 'season': 'minor',
    # },
    'ag_mod_m': { 'indexVars': {'hh_ID': 'case_id',
                                'field_ID': 'gardenid',
                                'plot_ID': 'plotid',
                                'crop': np.NaN,
                                'wave': np.NaN,
                                  },
                    'dataVars': {'hhCultivated_dum': 'ag_m0a',
                                'cropCode': 'crop_code',
                                # 'variety': 'ag_m0e',
                                # 'varietyOther': 'ag_m0e_oth',
                                # 'variety_localCompositeHybrid': 'ag_m0f',
                                'cropStand': 'ag_m01',
                                'plot_fullyCrop': 'ag_m02',
                                'plot_cropFrac': 'ag_m03',
                                'seeding_month': 'ag_m05a',
                                'seeding_year': 'ag_m05b',
                                'harvestStart_month': 'ag_m12a',
                                'harvestEnd_month': 'ag_m12b',
                                  },
                    'season': 'minor',
    },
}










### define dictionary for harmonization of crop-names: 2010 wave
cropNameHarmonize_dct_2010 = {
    # 'ag_mod_d': {'cropCols_lst': ['crop01', 'crop02', 'crop03', 'crop04', 'crop05'],
    #              'mainCropCol': 'crop01',
    #     },
    'ag_mod_g': {'cropCols_lst': ['cropCode', 'cropCode_other'],
                 'mainCropCol': 'cropCode',
        },
    # 'ag_mod_k': {'cropCols_lst': ['crop01', 'crop01_other', 'crop02', 'crop02_other', 'crop03', 'crop03_other', 'crop04', 'crop04_other', 'crop05', 'crop05_other'],
    #              'mainCropCol': 'crop01',
    #     },
    'ag_mod_m': {'cropCols_lst': ['cropCode', 'cropCode_other'],
                 'mainCropCol': 'cropCode',
        },
}


### define dictionary for harmonization of crop-names: 2013 wave
cropNameHarmonize_dct_2013 = {
    'ag_mod_g_13': {'cropCols_lst': ['cropCode'],
                 'mainCropCol': 'cropCode',
        },
    'ag_mod_m_13': {'cropCols_lst': ['cropCode'],
                 'mainCropCol': 'cropCode',
        },
}


### define dictionary for harmonization of crop-names: 2016 wave
cropNameHarmonize_dct_2016 = {
    # 'ag_mod_d': {'cropCols_lst': ['crop01', 'crop02', 'crop03', 'crop04', 'crop05'],
    #              'mainCropCol': 'crop01',
    #     },
    'ag_mod_g': {'cropCols_lst': ['cropCode'],
                 'mainCropCol': 'cropCode',
        },
    # 'ag_mod_k': {'cropCols_lst': ['crop01','crop02','crop03','crop04','crop05','crop_other'],
    #              'mainCropCol': 'crop01',
    #     },
    'ag_mod_m': {'cropCols_lst': ['cropCode'],
                 'mainCropCol': 'cropCode',
        },
}


### define dictionary for harmonization of crop-names: 2019 wave
cropNameHarmonize_dct_2019 = {
    # 'ag_mod_d_modified': {'cropCols_lst': ['crop01','crop02','crop03','crop04','crop05','crop_other01','crop_other02'], # additional variety information available in crop names here, if needed
    #      'mainCropCol': 'crop01',
    #     },
    'ag_mod_g': {'cropCols_lst': ['cropCode'],
         'mainCropCol': 'cropCode',
        },
    # 'ag_mod_k': {'cropCols_lst': ['crop01','crop02','crop03','crop04','crop05','crop_other01','crop_other02'],
    #      'mainCropCol': 'crop01',
    #     },
    'ag_mod_m': {'cropCols_lst': ['cropCode'],
         'mainCropCol': 'cropCode',
        },
}




cropNameConvert_dct = {
'nan': np.NaN,
'other (specify)': 'other',
'irish [malawi] potato': 'irish potato',
'therere/okra': 'okra',
'ground bean(nzama)': 'ground bean',
'tanaposi': 'chinese cabbage',
'finger millet(mawere)': 'finger millet',
'pigeonpea(nandolo)': 'pigeonpea',
'nkhwani': 'pumpkin leaves',
'pearl millet(mchewere)': 'pearl millet',
'sugar cane': 'sugarcane',
'maize: hybrid': 'maize',
'groundnut: chalimbana': 'groundnut',
'rice: mtupatupa': 'rice',
'groundnut: cg7': 'groundnut',
'tobacco: other specify': 'tobacco',
'rice: kilombero': 'rice',
'groundnut: mawanga': 'groundnut',
'rice: pusa': 'rice',
'tobacco: sdf': 'tobacco',
'rice: local': 'rice',
'groundnut: mani-pintar': 'groundnut',
'groundnut: other specify': 'groundnut',
'rice: tcg10': 'rice',
'tobacco: oriental': 'tobacco',
'rice: iet4094 (senga)': 'rice',
'maize: local': 'maize',
'tobacco: burley': 'tobacco',
'maize: composite/opv': 'maize',
'tobacco: flue cured': 'tobacco',
'rice: faya': 'rice',
'rice: wambone': 'rice',
'tobacco: nndf': 'tobacco',
'rape': 'rapeseed',
'coco': 'coconut',
'irish potatoes': 'irish potato',
'bonongwe': 'leafy greens',
'egg plants': 'eggplant',
'nali': np.NaN, # potentially chili pepper
'tomatoes': 'tomato',
'cucumbers': 'cucumber',
'11': np.NaN,
'rice mtupatupa': 'rice',
'groundbean': 'ground bean',
'other rice (specify)': 'rice',
'rice tcg10': 'rice',
'other specify 2': 'other',
'rice pusa': 'rice',
'other specify 1': 'other',
'rice iet4094 (senga)': 'rice',
'groundnuts winton': 'groundnut',
'groundnut chalimbana': 'groundnut',
'groundnut jl24': 'groundnut',
'maize composite/opv': 'maize',
'egg plant': 'eggplant',
'rice kilombero': 'rice',
'water melon': 'watermelon',
'tobacco oriental': 'tobacco',
'local maize and hybrid': 'maize',
'tobbaco': 'tobacco',
'cow peas': 'cowpeas',
'tobacco sdf': 'tobacco',
'sesame seeds': 'sesame',
'tobacco nndf': 'tobacco',
'groundnut mani-pintar': 'groundnut',
'rice local': 'rice',
'tambala rice': 'rice',
'other tobacco (specify)': 'tobacco',
'maize hybrid': 'maize',
'tobacco burley': 'tobacco',
'rice wambone': 'rice',
'rice ita': 'rice',
'rice faya': 'rice',
'tobacco flue cured': 'tobacco',
'groundnut mawanga': 'groundnut',
'groundnut cg7': 'groundnut',
'popcorn maize': 'maize',
'maize hybrid recycled': 'maize',
'other groundnut (specify)': 'groundnut',
'maize local': 'maize',
'pea': 'peas',
'49': np.NaN,
'therere': 'okra',
'masturd': 'mustard',
'cowpeas(nseula)': 'cowpeas',
'rice amboni': 'rice',
'chick pea (tchana)': 'chickpeas',
'mpiru (mustard)': 'mustard',
'indian hemp': 'hemp',
'carrot': 'carrots',
'green peas': 'green peas',
'mpilu': 'mustard',
'mpiru': 'mustard',
'yams': 'yam',
'tobacco labu': 'tobacco',
'cow peas (khobwe)': 'cowpeas',
'mustard/mpilu': 'mustard',
'water mill': 'watermelon',
'mustard mpilu': 'mustard',
}






### instantiate objects
####################################################################################################################
####################################################################################################################


### instatiate panel object
panel_MWI = Panel(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct)

### instatiate wave objects
MWI_2010 = SurveyWave(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2010, Path( str(data_folder_LSMS), '2010_2011/MWI_2010_IHS-III_v01_M_STATA8_DtaToCsvExport'), 'MWI_2010_IHS-III_v01_M', 'https://doi.org/10.48529/w1jq-qh85', modVar_dct_2010, cropNameHarmonize_dct_2010 )
MWI_2013 = SurveyWave(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2013, Path( str(data_folder_LSMS), '2010_2013_panel/MWI_2010-2013_IHPS_v01_M_Stata_DtaToCsvExport'), 'MWI_2010-2013_IHPS_v01_M', 'https://doi.org/10.48529/4q9f-2288', modVar_dct_2013, cropNameHarmonize_dct_2013 )
MWI_2016 = SurveyWave(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2016, Path( str(data_folder_LSMS), '2016_2017/MWI_2016_IHS-IV_v04_M_STATA14_DtaToCsvExport'), 'MWI_2016_IHS-IV_v04_M', 'https://doi.org/10.48529/g2p9-9r19', modVar_dct_2016, cropNameHarmonize_dct_2016 )
MWI_2019 = SurveyWave(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2019, Path( str(data_folder_LSMS), '2019_2020/MWI_2019_IHS-V_v05_M_Stata_DtaToCsvExport'), 'MWI_2019_IHS-V_v05_M', 'https://doi.org/10.48529/yqn3-zv74', modVar_dct_2019, cropNameHarmonize_dct_2019 )




### get list of modules
MWI_2010_module_lst = MWI_2010.modlue_lst
MWI_2013_module_lst = MWI_2013.modlue_lst
MWI_2016_module_lst = MWI_2016.modlue_lst
MWI_2019_module_lst = MWI_2019.modlue_lst


### harmonize and simplify cropnames
####################################################################################################################
####################################################################################################################

if __name__ == '__main__':


### merge modules into wave: 2010
####################################################################################################################
####################################################################################################################


    ### generate module-instances
    ##########
    MWI_2010_householdgeovariables = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2010, Path( str(data_folder_LSMS), '2010_2011/MWI_2010_IHS-III_v01_M_STATA8_DtaToCsvExport'), 'MWI_2010_IHS-IV_v04_M', 'https://doi.org/10.48529/g2p9-9r19', modVar_dct_2010, cropNameHarmonize_dct_2010, 'householdgeovariables' )
    MWI_2010_hh_mod_a_filt = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2010, Path( str(data_folder_LSMS), '2010_2011/MWI_2010_IHS-III_v01_M_STATA8_DtaToCsvExport'), 'MWI_2010_IHS-IV_v04_M', 'https://doi.org/10.48529/g2p9-9r19', modVar_dct_2010, cropNameHarmonize_dct_2010, 'hh_mod_a_filt' )
    MWI_2010_hh_mod_x = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2010, Path( str(data_folder_LSMS), '2010_2011/MWI_2010_IHS-III_v01_M_STATA8_DtaToCsvExport'), 'MWI_2010_IHS-IV_v04_M', 'https://doi.org/10.48529/g2p9-9r19', modVar_dct_2010, cropNameHarmonize_dct_2010, 'hh_mod_x' )
    MWI_2010_ag_mod_c = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2010, Path( str(data_folder_LSMS), '2010_2011/MWI_2010_IHS-III_v01_M_STATA8_DtaToCsvExport'), 'MWI_2010_IHS-IV_v04_M', 'https://doi.org/10.48529/g2p9-9r19', modVar_dct_2010, cropNameHarmonize_dct_2010, 'ag_mod_c' )
    # MWI_2010_ag_mod_d = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2010, Path( str(data_folder_LSMS), '2010_2011/MWI_2010_IHS-III_v01_M_STATA8_DtaToCsvExport'), 'MWI_2010_IHS-IV_v04_M', 'https://doi.org/10.48529/g2p9-9r19', modVar_dct_2010, cropNameHarmonize_dct_2010, 'ag_mod_d' )
    MWI_2010_ag_mod_g = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2010, Path( str(data_folder_LSMS), '2010_2011/MWI_2010_IHS-III_v01_M_STATA8_DtaToCsvExport'), 'MWI_2010_IHS-IV_v04_M', 'https://doi.org/10.48529/g2p9-9r19', modVar_dct_2010, cropNameHarmonize_dct_2010, 'ag_mod_g' )
    MWI_2010_ag_mod_j = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2010, Path( str(data_folder_LSMS), '2010_2011/MWI_2010_IHS-III_v01_M_STATA8_DtaToCsvExport'), 'MWI_2010_IHS-IV_v04_M', 'https://doi.org/10.48529/g2p9-9r19', modVar_dct_2010, cropNameHarmonize_dct_2010, 'ag_mod_j' )
    # MWI_2010_ag_mod_k = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2010, Path( str(data_folder_LSMS), '2010_2011/MWI_2010_IHS-III_v01_M_STATA8_DtaToCsvExport'), 'MWI_2010_IHS-IV_v04_M', 'https://doi.org/10.48529/g2p9-9r19', modVar_dct_2010, cropNameHarmonize_dct_2010, 'ag_mod_k' )
    MWI_2010_ag_mod_m = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2010, Path( str(data_folder_LSMS), '2010_2011/MWI_2010_IHS-III_v01_M_STATA8_DtaToCsvExport'), 'MWI_2010_IHS-IV_v04_M', 'https://doi.org/10.48529/g2p9-9r19', modVar_dct_2010, cropNameHarmonize_dct_2010, 'ag_mod_m' )


    ### generate module-dataframes
    ##########
    MWI_2010_householdgeovariables_pd = MWI_2010_householdgeovariables.module_pd
    MWI_2010_hh_mod_a_filt_pd = MWI_2010_hh_mod_a_filt.module_pd
    MWI_2010_hh_mod_x_pd = MWI_2010_hh_mod_x.module_pd
    MWI_2010_ag_mod_c_pd = MWI_2010_ag_mod_c.module_pd
    # MWI_2010_ag_mod_d_pd = MWI_2010_ag_mod_d.module_pd
    MWI_2010_ag_mod_g_pd = MWI_2010_ag_mod_g.module_pd
    MWI_2010_ag_mod_j_pd = MWI_2010_ag_mod_j.module_pd
    # MWI_2010_ag_mod_k_pd = MWI_2010_ag_mod_k.module_pd
    MWI_2010_ag_mod_m_pd = MWI_2010_ag_mod_m.module_pd

    ### consult index variables of each module
    ##########
    MWI_2010_householdgeovariables.indexVar_lst
    MWI_2010_hh_mod_a_filt.indexVar_lst
    MWI_2010_hh_mod_x.indexVar_lst
    MWI_2010_ag_mod_c.indexVar_lst
    # MWI_2010_ag_mod_d.indexVar_lst
    MWI_2010_ag_mod_g.indexVar_lst
    MWI_2010_ag_mod_j.indexVar_lst
    # MWI_2010_ag_mod_k.indexVar_lst
    MWI_2010_ag_mod_m.indexVar_lst

    ### consult season of each module
    ##########
    MWI_2010_householdgeovariables.season
    MWI_2010_hh_mod_a_filt.season
    MWI_2010_hh_mod_x.season
    # MWI_2010_ag_mod_d.season
    MWI_2010_ag_mod_g.season
    MWI_2010_ag_mod_c.season
    # MWI_2010_ag_mod_k.season
    MWI_2010_ag_mod_m.season
    MWI_2010_ag_mod_j.season


    ### merge major season modules
    ##########
    print('Starting merge for major season.')
    
    
    # (a) Level: 'wave', 'season', 'hh_ID', 'plot_ID', 'crop'
    # (b) Level: 'wave', 'season', 'hh_ID', 'plot_ID'
    print('Prior to merge, MWI_2010_ag_mod_g_pd is of shape', MWI_2010_ag_mod_g_pd.shape)
    print('Prior to merge, MWI_2010_ag_mod_c_pd is of shape', MWI_2010_ag_mod_c_pd.shape)
    MWI_2010_major_pd = MWI_2010_ag_mod_g_pd.merge(MWI_2010_ag_mod_c_pd, on = MWI_2010_ag_mod_c.indexVar_lst, how = 'left', validate='m:1')
    print('After merge, MWI_2010_major_pd is of shape', MWI_2010_major_pd.shape)

    
    ### merge minor season modules
    ##########
    print('Starting merge for minor season.')

    # (a) Level: 'wave', 'season', 'hh_ID', 'plot_ID', 'crop'
    # (b) Level: 'wave', 'season', 'hh_ID', 'plot_ID'
    print('Prior to merge, MWI_2010_ag_mod_m_pd is of shape', MWI_2010_ag_mod_m_pd.shape)
    print('Prior to merge, MWI_2010_ag_mod_j_pd is of shape', MWI_2010_ag_mod_j_pd.shape)
    MWI_2010_minor_pd = MWI_2010_ag_mod_m_pd.merge(MWI_2010_ag_mod_j_pd, on = MWI_2010_ag_mod_j.indexVar_lst, how = 'left', validate='m:1')
    print('After merge, MWI_2010_minor_pd is of shape', MWI_2010_minor_pd.shape)


    ### concat major and minor season modules
    ##########
    MWI_2010_pd = pd.concat( [MWI_2010_major_pd, MWI_2010_minor_pd], axis=0, join="outer", ignore_index=True)
    print('After concatenation of major- and minor-season dataframes, MWI_2010_pd is of shape', MWI_2010_pd.shape)



    ### merge season-generic modules
    ##########
    ### 
    print('Starting merge for season-generic dataframes.')

    # (c) Level: 'wave', 'hh_ID'
    print('Prior to merge, MWI_2010_hh_mod_x_pd is of shape', MWI_2010_hh_mod_x_pd.shape)
    MWI_2010_pd = MWI_2010_pd.merge(MWI_2010_hh_mod_x_pd, on = MWI_2010_hh_mod_x.indexVar_lst, how = 'left')
    print('After merge, MWI_2010_pd is of shape', MWI_2010_pd.shape)

    print('Prior to merge, MWI_2010_householdgeovariables_pd is of shape', MWI_2010_householdgeovariables_pd.shape)
    MWI_2010_pd = MWI_2010_pd.merge(MWI_2010_householdgeovariables_pd, on = MWI_2010_householdgeovariables.indexVar_lst, how = 'left')
    print('After merge, MWI_2010_pd is of shape', MWI_2010_pd.shape)

    print('Prior to merge, MWI_2010_hh_mod_a_filt is of shape', MWI_2010_hh_mod_a_filt_pd.shape)
    MWI_2010_pd = MWI_2010_pd.merge(MWI_2010_hh_mod_a_filt_pd, on = MWI_2010_hh_mod_a_filt.indexVar_lst, how = 'left')
    print('After merge, MWI_2010_pd is of shape', MWI_2010_pd.shape)



    ### save wave to disk
    ##########
    MWI_2010_pd.to_csv( Path( str(project_path), 'LSMS_MWI_ingested', 'MWI_2010_ingested.csv') )






### merge modules into wave: 2013
####################################################################################################################
####################################################################################################################

    ### generate module-instances
    ##########
    MWI_2013_householdgeovariables_ihps_13 = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2013, Path( str(data_folder_LSMS), '2010_2013_panel/MWI_2010-2013_IHPS_v01_M_Stata_DtaToCsvExport'), 'MWI_2010-2013_IHPS_v01_M', 'https://doi.org/10.48529/4q9f-2288', modVar_dct_2013, cropNameHarmonize_dct_2013, 'householdgeovariables_ihps_13' )
    MWI_2013_hh_mod_a_filt_13 = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2013, Path( str(data_folder_LSMS), '2010_2013_panel/MWI_2010-2013_IHPS_v01_M_Stata_DtaToCsvExport'), 'MWI_2010-2013_IHPS_v01_M', 'https://doi.org/10.48529/4q9f-2288', modVar_dct_2013, cropNameHarmonize_dct_2013, 'hh_mod_a_filt_13' )
    MWI_2013_hh_mod_x_13 = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2013, Path( str(data_folder_LSMS), '2010_2013_panel/MWI_2010-2013_IHPS_v01_M_Stata_DtaToCsvExport'), 'MWI_2010-2013_IHPS_v01_M', 'https://doi.org/10.48529/4q9f-2288', modVar_dct_2013, cropNameHarmonize_dct_2013, 'hh_mod_x_13' )
    MWI_2013_ag_mod_c_13 = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2013, Path( str(data_folder_LSMS), '2010_2013_panel/MWI_2010-2013_IHPS_v01_M_Stata_DtaToCsvExport'), 'MWI_2010-2013_IHPS_v01_M', 'https://doi.org/10.48529/4q9f-2288', modVar_dct_2013, cropNameHarmonize_dct_2013, 'ag_mod_c_13' )
    MWI_2013_ag_mod_g_13 = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2013, Path( str(data_folder_LSMS), '2010_2013_panel/MWI_2010-2013_IHPS_v01_M_Stata_DtaToCsvExport'), 'MWI_2010-2013_IHPS_v01_M', 'https://doi.org/10.48529/4q9f-2288', modVar_dct_2013, cropNameHarmonize_dct_2013, 'ag_mod_g_13' )
    MWI_2013_ag_mod_j_13 = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2013, Path( str(data_folder_LSMS), '2010_2013_panel/MWI_2010-2013_IHPS_v01_M_Stata_DtaToCsvExport'), 'MWI_2010-2013_IHPS_v01_M', 'https://doi.org/10.48529/4q9f-2288', modVar_dct_2013, cropNameHarmonize_dct_2013, 'ag_mod_j_13' )
    MWI_2013_ag_mod_m_13 = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2013, Path( str(data_folder_LSMS), '2010_2013_panel/MWI_2010-2013_IHPS_v01_M_Stata_DtaToCsvExport'), 'MWI_2010-2013_IHPS_v01_M', 'https://doi.org/10.48529/4q9f-2288', modVar_dct_2013, cropNameHarmonize_dct_2013, 'ag_mod_m_13' )
    
    
    ### generate module-dataframes
    ##########
    MWI_2013_householdgeovariables_ihps_13_pd = MWI_2013_householdgeovariables_ihps_13.module_pd
    MWI_2013_hh_mod_a_filt_13_pd = MWI_2013_hh_mod_a_filt_13.module_pd
    MWI_2013_hh_mod_x_13_pd = MWI_2013_hh_mod_x_13.module_pd
    MWI_2013_ag_mod_c_13_pd = MWI_2013_ag_mod_c_13.module_pd
    MWI_2013_ag_mod_g_13_pd = MWI_2013_ag_mod_g_13.module_pd
    MWI_2013_ag_mod_j_13_pd = MWI_2013_ag_mod_j_13.module_pd
    MWI_2013_ag_mod_m_13_pd = MWI_2013_ag_mod_m_13.module_pd
    
    ### consult index variables of each module
    ##########
    MWI_2013_householdgeovariables_ihps_13.indexVar_lst
    MWI_2013_hh_mod_a_filt_13.indexVar_lst
    MWI_2013_hh_mod_x_13.indexVar_lst
    MWI_2013_ag_mod_c_13.indexVar_lst
    MWI_2013_ag_mod_g_13.indexVar_lst
    MWI_2013_ag_mod_j_13.indexVar_lst
    MWI_2013_ag_mod_m_13.indexVar_lst
    
    ### consult season of each module
    ##########
    MWI_2013_householdgeovariables_ihps_13.season
    MWI_2013_hh_mod_a_filt_13.season
    MWI_2013_hh_mod_x_13.season
    MWI_2013_ag_mod_c_13.season
    MWI_2013_ag_mod_g_13.season
    MWI_2013_ag_mod_j_13.season
    MWI_2013_ag_mod_m_13.season
    

    ### merge major season modules
    ##########
    print('Starting merge for major season.')
    
    # Level: 'wave', 'season', 'hh_ID', 'field_ID', 'plot_ID' WITH 'wave', 'season', 'hh_ID', 'plot_ID', 'crop'
    print('Prior to merge, MWI_2013_ag_mod_c_13_pd is of shape', MWI_2013_ag_mod_c_13_pd.shape)
    print('Prior to merge, MWI_2013_ag_mod_g_13_pd is of shape', MWI_2013_ag_mod_g_13_pd.shape)
    # note: merge operation is validating that this is a many-to-one merge, i.e., an identical plot is allowed to have various crops, but there may only be one plot
    MWI_2013_major_pd = MWI_2013_ag_mod_g_13_pd.merge(MWI_2013_ag_mod_c_13_pd, on = ['wave', 'season', 'hh_ID', 'plot_ID'], how = 'left', validate='m:1')
    print('After merge, MWI_2013_major_pd is of shape', MWI_2013_major_pd.shape)
    


    
    ### merge minor season modules
    ##########
    print('Starting merge for minor season.')
        
    # Level: 'wave', 'season', 'hh_ID', 'field_ID', 'plot_ID', 'crop' WITH 'wave', 'season', 'hh_ID', 'field_ID', 'plot_ID'
    print('Prior to merge, MWI_2013_ag_mod_j_13_pd is of shape', MWI_2013_ag_mod_j_13_pd.shape)
    print('Prior to merge, MWI_2013_ag_mod_m_13_pd is of shape', MWI_2013_ag_mod_m_13_pd.shape)
    # note: merge operation is validating that this is a many-to-one merge, i.e., an identical plot is allowed to have various crops, but there may only be one plot
    MWI_2013_minor_pd = MWI_2013_ag_mod_m_13_pd.merge(MWI_2013_ag_mod_j_13_pd, on = MWI_2013_ag_mod_j_13.indexVar_lst, how = 'left', validate='m:1')
    print('After merge, MWI_2013_minor_pd is of shape', MWI_2013_minor_pd.shape)
    
    
    ### concat major and minor season modules
    ##########
    MWI_2013_pd = pd.concat( [MWI_2013_major_pd, MWI_2013_minor_pd], axis=0, join="outer", ignore_index=True)
    print('After concatenation of major- and minor-season dataframes, MWI_2013_pd is of shape', MWI_2013_pd.shape)
    
    
    
    ### merge season-generic modules
    ##########
    ### 
    print('Starting merge for season-generic dataframes.')
   
    # (c) Level: 'wave', 'hh_ID'
    print('Prior to merge, MWI_2013_hh_mod_x_13_pd is of shape', MWI_2013_hh_mod_x_13_pd.shape)
    MWI_2013_pd = MWI_2013_pd.merge(MWI_2013_hh_mod_x_13_pd, on = MWI_2013_hh_mod_x_13.indexVar_lst, how = 'left')
    print('After merge, MWI_2013_pd is of shape', MWI_2013_pd.shape)
    
    print('Prior to merge, MWI_2013_householdgeovariables_ihps_13_pd is of shape', MWI_2013_householdgeovariables_ihps_13_pd.shape)
    MWI_2013_pd = MWI_2013_pd.merge(MWI_2013_householdgeovariables_ihps_13_pd, on = MWI_2013_householdgeovariables_ihps_13.indexVar_lst, how = 'left')
    print('After merge, MWI_2013_pd is of shape', MWI_2013_pd.shape)
    
    print('Prior to merge, MWI_2013_hh_mod_a_filt_13_pd is of shape', MWI_2013_hh_mod_a_filt_13_pd.shape)
    MWI_2013_pd = MWI_2013_pd.merge(MWI_2013_hh_mod_a_filt_13_pd, on = MWI_2013_hh_mod_a_filt_13.indexVar_lst, how = 'left')
    print('After merge, MWI_2013_pd is of shape', MWI_2013_pd.shape)
    
    
    ### save wave to disk
    ##########
    MWI_2013_pd.to_csv( Path( str(project_path), 'LSMS_MWI_ingested', 'MWI_2013_ingested.csv') )





### merge modules into wave: 2016
####################################################################################################################
####################################################################################################################


    ### generate module-instances
    ##########
    MWI_2016_householdgeovariablesihs4 = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2016, Path( str(data_folder_LSMS), '2016_2017/MWI_2016_IHS-IV_v04_M_STATA14_DtaToCsvExport'), 'MWI_2016_IHS-IV_v04_M', 'https://doi.org/10.48529/g2p9-9r19', modVar_dct_2016, cropNameHarmonize_dct_2016, 'householdgeovariablesihs4' )
    MWI_2016_hh_mod_a_filt = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2016, Path( str(data_folder_LSMS), '2016_2017/MWI_2016_IHS-IV_v04_M_STATA14_DtaToCsvExport'), 'MWI_2016_IHS-IV_v04_M', 'https://doi.org/10.48529/g2p9-9r19', modVar_dct_2016, cropNameHarmonize_dct_2016, 'hh_mod_a_filt' )
    MWI_2016_hh_mod_x = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2016, Path( str(data_folder_LSMS), '2016_2017/MWI_2016_IHS-IV_v04_M_STATA14_DtaToCsvExport'), 'MWI_2016_IHS-IV_v04_M', 'https://doi.org/10.48529/g2p9-9r19', modVar_dct_2016, cropNameHarmonize_dct_2016, 'hh_mod_x' )
    MWI_2016_ag_mod_c = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2016, Path( str(data_folder_LSMS), '2016_2017/MWI_2016_IHS-IV_v04_M_STATA14_DtaToCsvExport'), 'MWI_2016_IHS-IV_v04_M', 'https://doi.org/10.48529/g2p9-9r19', modVar_dct_2016, cropNameHarmonize_dct_2016, 'ag_mod_c' )
    # MWI_2016_ag_mod_d = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2016, Path( str(data_folder_LSMS), '2016_2017/MWI_2016_IHS-IV_v04_M_STATA14_DtaToCsvExport'), 'MWI_2016_IHS-IV_v04_M', 'https://doi.org/10.48529/g2p9-9r19', modVar_dct_2016, cropNameHarmonize_dct_2016, 'ag_mod_d' )
    MWI_2016_ag_mod_g = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2016, Path( str(data_folder_LSMS), '2016_2017/MWI_2016_IHS-IV_v04_M_STATA14_DtaToCsvExport'), 'MWI_2016_IHS-IV_v04_M', 'https://doi.org/10.48529/g2p9-9r19', modVar_dct_2016, cropNameHarmonize_dct_2016, 'ag_mod_g' )
    MWI_2016_ag_mod_j = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2016, Path( str(data_folder_LSMS), '2016_2017/MWI_2016_IHS-IV_v04_M_STATA14_DtaToCsvExport'), 'MWI_2016_IHS-IV_v04_M', 'https://doi.org/10.48529/g2p9-9r19', modVar_dct_2016, cropNameHarmonize_dct_2016, 'ag_mod_j' )
    # MWI_2016_ag_mod_k = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2016, Path( str(data_folder_LSMS), '2016_2017/MWI_2016_IHS-IV_v04_M_STATA14_DtaToCsvExport'), 'MWI_2016_IHS-IV_v04_M', 'https://doi.org/10.48529/g2p9-9r19', modVar_dct_2016, cropNameHarmonize_dct_2016, 'ag_mod_k' )
    MWI_2016_ag_mod_m = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2016, Path( str(data_folder_LSMS), '2016_2017/MWI_2016_IHS-IV_v04_M_STATA14_DtaToCsvExport'), 'MWI_2016_IHS-IV_v04_M', 'https://doi.org/10.48529/g2p9-9r19', modVar_dct_2016, cropNameHarmonize_dct_2016, 'ag_mod_m' )


    ### generate module-dataframes
    ##########
    MWI_2016_householdgeovariablesihs4_pd = MWI_2016_householdgeovariablesihs4.module_pd
    MWI_2016_hh_mod_a_filt_pd = MWI_2016_hh_mod_a_filt.module_pd
    MWI_2016_hh_mod_x_pd = MWI_2016_hh_mod_x.module_pd
    MWI_2016_ag_mod_c_pd = MWI_2016_ag_mod_c.module_pd
    # MWI_2016_ag_mod_d_pd = MWI_2016_ag_mod_d.module_pd
    MWI_2016_ag_mod_g_pd = MWI_2016_ag_mod_g.module_pd
    MWI_2016_ag_mod_j_pd = MWI_2016_ag_mod_j.module_pd
    # MWI_2016_ag_mod_k_pd = MWI_2016_ag_mod_k.module_pd
    MWI_2016_ag_mod_m_pd = MWI_2016_ag_mod_m.module_pd

    ### consult index variables of each module
    ##########
    MWI_2016_householdgeovariablesihs4.indexVar_lst
    MWI_2016_hh_mod_a_filt.indexVar_lst
    MWI_2016_hh_mod_x.indexVar_lst
    MWI_2016_ag_mod_c.indexVar_lst
    # MWI_2016_ag_mod_d.indexVar_lst
    MWI_2016_ag_mod_g.indexVar_lst
    MWI_2016_ag_mod_j.indexVar_lst
    # MWI_2016_ag_mod_k.indexVar_lst
    MWI_2016_ag_mod_m.indexVar_lst

    ### consult season of each module
    ##########
    MWI_2016_householdgeovariablesihs4.season
    MWI_2016_hh_mod_a_filt.season
    MWI_2016_hh_mod_x.season
    # MWI_2016_ag_mod_d.season
    MWI_2016_ag_mod_g.season
    MWI_2016_ag_mod_c.season
    # MWI_2016_ag_mod_k.season
    MWI_2016_ag_mod_m.season
    MWI_2016_ag_mod_j.season


    ### merge major season modules
    ##########
    print('Starting merge for major season.')
    # (a) Level: 'wave', 'season', 'hh_ID', 'field_ID', 'plot_ID', 'crop'
    print('Prior to merge, MWI_2016_ag_mod_d_pd is of shape', MWI_2016_ag_mod_d_pd.shape)
    print('Prior to merge, MWI_2016_ag_mod_g_pd is of shape', MWI_2016_ag_mod_g_pd.shape)
    MWI_2016_major_pd = MWI_2016_ag_mod_d_pd.merge(MWI_2016_ag_mod_g_pd, on = MWI_2016_ag_mod_d.indexVar_lst, how = 'outer')
    print('After merge, MWI_2016_major_crop_pd is of shape', MWI_2016_major_pd.shape)
    # (b) Level: 'wave', 'season', 'hh_ID', 'field_ID', 'plot_ID'
    print('Prior to merge, MWI_2016_ag_mod_c_pd is of shape', MWI_2016_ag_mod_c_pd.shape)
    MWI_2016_major_pd = MWI_2016_major_pd.merge(MWI_2016_ag_mod_c_pd, on = MWI_2016_ag_mod_c.indexVar_lst, how = 'left')
    print('After merge, MWI_2016_major_pd is of shape', MWI_2016_major_pd.shape)

    
    ### merge minor season modules
    ##########
    print('Starting merge for minor season.')

    # (a) Level: 'wave', 'season', 'hh_ID', 'field_ID', 'plot_ID', 'crop'
    print('Prior to merge, MWI_2016_ag_mod_k_pd is of shape', MWI_2016_ag_mod_k_pd.shape)
    print('Prior to merge, MWI_2016_ag_mod_m_pd is of shape', MWI_2016_ag_mod_m_pd.shape)
    MWI_2016_minor_pd = MWI_2016_ag_mod_k_pd.merge(MWI_2016_ag_mod_m_pd, on = MWI_2016_ag_mod_k.indexVar_lst, how = 'outer')
    print('After merge, MWI_2016_minor_pd is of shape', MWI_2016_minor_pd.shape)

    # (b) Level: 'wave', 'season', 'hh_ID', 'field_ID', 'plot_ID'
    print('Prior to merge, MWI_2016_ag_mod_j_pd is of shape', MWI_2016_ag_mod_j_pd.shape)
    MWI_2016_minor_pd = MWI_2016_minor_pd.merge(MWI_2016_ag_mod_j_pd, on = MWI_2016_ag_mod_j.indexVar_lst, how = 'left')
    print('After merge, MWI_2016_minor_pd is of shape', MWI_2016_minor_pd.shape)


    ### concat major and minor season modules
    ##########
    MWI_2016_pd = pd.concat( [MWI_2016_major_pd, MWI_2016_minor_pd], axis=0, join="outer", ignore_index=True)
    print('After concatenation of major- and minor-season dataframes, MWI_2016_pd is of shape', MWI_2016_pd.shape)



    ### merge season-generic modules
    ##########
    ### 
    print('Starting merge for season-generic dataframes.')

    # (c) Level: 'wave', 'hh_ID'
    print('Prior to merge, MWI_2016_hh_mod_x_pd is of shape', MWI_2016_hh_mod_x_pd.shape)
    MWI_2016_pd = MWI_2016_pd.merge(MWI_2016_hh_mod_x_pd, on = MWI_2016_hh_mod_x.indexVar_lst, how = 'left')
    print('After merge, MWI_2016_pd is of shape', MWI_2016_pd.shape)

    print('Prior to merge, MWI_2016_householdgeovariablesihs4_pd is of shape', MWI_2016_householdgeovariablesihs4_pd.shape)
    MWI_2016_pd = MWI_2016_pd.merge(MWI_2016_householdgeovariablesihs4_pd, on = MWI_2016_householdgeovariablesihs4.indexVar_lst, how = 'left')
    print('After merge, MWI_2016_pd is of shape', MWI_2016_pd.shape)

    print('Prior to merge, MWI_2016_hh_mod_a_filt_pd is of shape', MWI_2016_hh_mod_a_filt_pd.shape)
    MWI_2016_pd = MWI_2016_pd.merge(MWI_2016_hh_mod_a_filt_pd, on = MWI_2016_hh_mod_a_filt.indexVar_lst, how = 'left')
    print('After merge, MWI_2016_pd is of shape', MWI_2016_pd.shape)



    ### save wave to disk
    ##########
    MWI_2016_pd.to_csv( Path( str(project_path), 'LSMS_MWI_ingested', 'MWI_2016_ingested.csv') )





### merge modules into wave: 2019
####################################################################################################################
####################################################################################################################


    ### generate Module-instances
    ##########
    MWI_2019_householdgeovariables_ihs5 = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2019, Path( str(data_folder_LSMS), '2019_2020/MWI_2019_IHS-V_v05_M_Stata_DtaToCsvExport'), 'MWI_2019_IHS-V_v05_M', 'https://doi.org/10.48529/yqn3-zv74', modVar_dct_2019, cropNameHarmonize_dct_2019, 'householdgeovariables_ihs5' )
    MWI_2019_hh_mod_a_filt = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2019, Path( str(data_folder_LSMS), '2019_2020/MWI_2019_IHS-V_v05_M_Stata_DtaToCsvExport'), 'MWI_2019_IHS-V_v05_M', 'https://doi.org/10.48529/yqn3-zv74', modVar_dct_2019, cropNameHarmonize_dct_2019, 'hh_mod_a_filt' )
    MWI_2019_hh_mod_x = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2019, Path( str(data_folder_LSMS), '2019_2020/MWI_2019_IHS-V_v05_M_Stata_DtaToCsvExport'), 'MWI_2019_IHS-V_v05_M', 'https://doi.org/10.48529/yqn3-zv74', modVar_dct_2019, cropNameHarmonize_dct_2019, 'hh_mod_x' )
    MWI_2019_ag_mod_c = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2019, Path( str(data_folder_LSMS), '2019_2020/MWI_2019_IHS-V_v05_M_Stata_DtaToCsvExport'), 'MWI_2019_IHS-V_v05_M', 'https://doi.org/10.48529/yqn3-zv74', modVar_dct_2019, cropNameHarmonize_dct_2019, 'ag_mod_c' )
    MWI_2019_ag_mod_d_modified = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2019, Path( str(data_folder_LSMS), '2019_2020/MWI_2019_IHS-V_v05_M_Stata_DtaToCsvExport'), 'MWI_2019_IHS-V_v05_M', 'https://doi.org/10.48529/yqn3-zv74', modVar_dct_2019, cropNameHarmonize_dct_2019, 'ag_mod_d_modified' )
    MWI_2019_ag_mod_g = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2019, Path( str(data_folder_LSMS), '2019_2020/MWI_2019_IHS-V_v05_M_Stata_DtaToCsvExport'), 'MWI_2019_IHS-V_v05_M', 'https://doi.org/10.48529/yqn3-zv74', modVar_dct_2019, cropNameHarmonize_dct_2019, 'ag_mod_g' )
    MWI_2019_ag_mod_j = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2019, Path( str(data_folder_LSMS), '2019_2020/MWI_2019_IHS-V_v05_M_Stata_DtaToCsvExport'), 'MWI_2019_IHS-V_v05_M', 'https://doi.org/10.48529/yqn3-zv74', modVar_dct_2019, cropNameHarmonize_dct_2019, 'ag_mod_j' )
    MWI_2019_ag_mod_k = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2019, Path( str(data_folder_LSMS), '2019_2020/MWI_2019_IHS-V_v05_M_Stata_DtaToCsvExport'), 'MWI_2019_IHS-V_v05_M', 'https://doi.org/10.48529/yqn3-zv74', modVar_dct_2019, cropNameHarmonize_dct_2019, 'ag_mod_k' )
    MWI_2019_ag_mod_m = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2019, Path( str(data_folder_LSMS), '2019_2020/MWI_2019_IHS-V_v05_M_Stata_DtaToCsvExport'), 'MWI_2019_IHS-V_v05_M', 'https://doi.org/10.48529/yqn3-zv74', modVar_dct_2019, cropNameHarmonize_dct_2019, 'ag_mod_m' )


    ### generate module-dataframes
    ##########
    MWI_2019_householdgeovariables_ihs5_pd = MWI_2019_householdgeovariables_ihs5.module_pd
    MWI_2019_hh_mod_a_filt_pd = MWI_2019_hh_mod_a_filt.module_pd   
    MWI_2019_hh_mod_x_pd = MWI_2019_hh_mod_x.module_pd   
    MWI_2019_ag_mod_c_pd = MWI_2019_ag_mod_c.module_pd
    MWI_2019_ag_mod_d_modified_pd = MWI_2019_ag_mod_d_modified.module_pd
    MWI_2019_ag_mod_g_pd = MWI_2019_ag_mod_g.module_pd
    MWI_2019_ag_mod_j_pd = MWI_2019_ag_mod_j.module_pd
    MWI_2019_ag_mod_k_pd = MWI_2019_ag_mod_k.module_pd
    MWI_2019_ag_mod_m_pd = MWI_2019_ag_mod_m.module_pd

    ### consult index variables of each module
    ##########
    MWI_2019_householdgeovariables_ihs5.indexVar_lst
    MWI_2019_hh_mod_a_filt.indexVar_lst
    MWI_2019_hh_mod_x.indexVar_lst
    MWI_2019_ag_mod_c.indexVar_lst
    MWI_2019_ag_mod_d_modified.indexVar_lst
    MWI_2019_ag_mod_g.indexVar_lst
    MWI_2019_ag_mod_j.indexVar_lst
    MWI_2019_ag_mod_k.indexVar_lst
    MWI_2019_ag_mod_m.indexVar_lst

    ### consult season of each module
    ##########
    MWI_2019_householdgeovariables_ihs5.season
    MWI_2019_hh_mod_a_filt.season
    MWI_2019_hh_mod_x.season
    MWI_2019_ag_mod_d_modified_pd.season
    MWI_2019_ag_mod_g.season
    MWI_2019_ag_mod_c.season
    MWI_2019_ag_mod_k.season
    MWI_2019_ag_mod_m.season
    MWI_2019_ag_mod_j.season



    ### merge major season modules
    ##########
    print('Starting merge for major season.')
    # (a) Level: 'wave', 'season', 'hh_ID', 'field_ID', 'plot_ID', 'crop'
    print('Prior to merge, MWI_2019_ag_mod_d_modified_pd is of shape', MWI_2019_ag_mod_d_modified_pd.shape)
    print('Prior to merge, MWI_2019_ag_mod_g_pd is of shape', MWI_2019_ag_mod_g_pd.shape)
    MWI_2019_major_pd = MWI_2019_ag_mod_d_modified_pd.merge(MWI_2019_ag_mod_g_pd, on = MWI_2019_ag_mod_d_modified.indexVar_lst, how = 'outer')
    print('After merge, MWI_2019_major_crop_pd is of shape', MWI_2019_major_pd.shape)
    # (b) Level: 'wave', 'season', 'hh_ID', 'field_ID', 'plot_ID'
    print('Prior to merge, MWI_2019_ag_mod_c_pd is of shape', MWI_2019_ag_mod_c_pd.shape)
    MWI_2019_major_pd = MWI_2019_major_pd.merge(MWI_2019_ag_mod_c_pd, on = MWI_2019_ag_mod_c.indexVar_lst, how = 'left')
    print('After merge, MWI_2019_major_pd is of shape', MWI_2019_major_pd.shape)

    
    ### merge minor season modules
    ##########
    print('Starting merge for minor season.')

    # (a) Level: 'wave', 'season', 'hh_ID', 'field_ID', 'plot_ID', 'crop'
    print('Prior to merge, MWI_2019_ag_mod_k_pd is of shape', MWI_2019_ag_mod_k_pd.shape)
    print('Prior to merge, MWI_2019_ag_mod_m_pd is of shape', MWI_2019_ag_mod_m_pd.shape)
    MWI_2019_minor_pd = MWI_2019_ag_mod_k_pd.merge(MWI_2019_ag_mod_m_pd, on = MWI_2019_ag_mod_k.indexVar_lst, how = 'outer')
    print('After merge, MWI_2019_minor_pd is of shape', MWI_2019_minor_pd.shape)

    # (b) Level: 'wave', 'season', 'hh_ID', 'field_ID', 'plot_ID'
    print('Prior to merge, MWI_2019_ag_mod_j_pd is of shape', MWI_2019_ag_mod_j_pd.shape)
    MWI_2019_minor_pd = MWI_2019_minor_pd.merge(MWI_2019_ag_mod_j_pd, on = MWI_2019_ag_mod_j.indexVar_lst, how = 'left')
    print('After merge, MWI_2019_minor_pd is of shape', MWI_2019_minor_pd.shape)


    ### concat major and minor season modules
    ##########
    MWI_2019_pd = pd.concat( [MWI_2019_major_pd, MWI_2019_minor_pd], axis=0, join="outer", ignore_index=True)
    print('After concatenation of major- and minor-season dataframes, MWI_2019_pd is of shape', MWI_2019_pd.shape)



    ### merge season-generic modules
    ##########
    ### 
    print('Starting merge for season-generic dataframes.')

    # (c) Level: 'wave', 'hh_ID'
    print('Prior to merge, MWI_2019_hh_mod_x_pd is of shape', MWI_2019_hh_mod_x_pd.shape)
    MWI_2019_pd = MWI_2019_pd.merge(MWI_2019_hh_mod_x_pd, on = MWI_2019_hh_mod_x.indexVar_lst, how = 'left')
    print('After merge, MWI_2019_pd is of shape', MWI_2019_pd.shape)

    print('Prior to merge, MWI_2019_householdgeovariables_ihs5_pd is of shape', MWI_2019_householdgeovariables_ihs5_pd.shape)
    MWI_2019_pd = MWI_2019_pd.merge(MWI_2019_householdgeovariables_ihs5_pd, on = MWI_2019_householdgeovariables_ihs5.indexVar_lst, how = 'left')
    print('After merge, MWI_2019_pd is of shape', MWI_2019_pd.shape)

    print('Prior to merge, MWI_2019_hh_mod_a_filt_pd is of shape', MWI_2019_hh_mod_a_filt_pd.shape)
    MWI_2019_pd = MWI_2019_pd.merge(MWI_2019_hh_mod_a_filt_pd, on = MWI_2019_hh_mod_a_filt.indexVar_lst, how = 'left')
    print('After merge, MWI_2019_pd is of shape', MWI_2019_pd.shape)


    ### save wave to disk
    ##########
    MWI_2019_pd.to_csv( Path( str(project_path), 'LSMS_MWI_ingested', 'MWI_2019_ingested.csv') )







### concat waves into panel
####################################################################################################################
####################################################################################################################

    # concat all waves into panel
    panel_MWI_pd = pd.concat( [MWI_2016_pd, MWI_2019_pd], axis=0, join="outer", ignore_index=True )

    panel_MWI_collst = panel_MWI_pd.columns.to_list()

    # identify columns that are not in both dataframes
    col2016_unique = []
    for col2016 in MWI_2016_pd.columns:
        if col2016 not in MWI_2019_pd.columns:
            col2016_unique.append(col2016)

    col2019_unique = []
    for col2019 in MWI_2019_pd.columns:
        if col2019 not in MWI_2016_pd.columns:
            col2019_unique.append(col2019)

    # save panel to disk
    panel_MWI_pd.to_csv( Path( str(project_path), 'LSMS_MWI_ingested', 'MWI_panel_ingested.csv' ), index=False )




### anecdotal testing
####################################################################################################################
####################################################################################################################


    panel_MWI.country
    MWI_2016.wave
    MWI_2016_indexVars_tpl = MWI_2016.indexVars_tpl
