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

    def __init__(self, country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, wave, wave_csvFolder, modVar_dct, cropNameHarmonize_dct, module_name):

        ### inherinting __init__ from SurveyWave
        #######
        SurveyWave.__init__(self, country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, wave, wave_csvFolder, modVar_dct, cropNameHarmonize_dct)

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
        module_pd = pd.read_csv( Path( str(self.wave_csvFolder), f'{self.module_name}.csv' ) )

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
                module_pd[cropCol] = module_pd[cropCol].str.lower().str.strip()

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
wave_lst = [2004, 2010, 2016, 2019]
# wave_lst = [2004, 2010, 2013, 2016, 2019]


### define index variables of panel
panel_indexVars_lst = ['wave', 'season', 'hh_ID', 'field_ID', 'plot_ID', 'crop']



##### define module-variable dictionary: 2004 wave
####################
modVar_dct_2004 = {
        
    'sec_n': { 'indexVars': { 
                            'hh_ID': 'case_id',
                            'hh_ID2': 'hhid',
                            'field_ID': '',
                            'plot_ID': '',
                            'crop': np.NaN,
                            'wave': np.NaN,
                              },
                    'dataVars': {
                                 'region_ID': 'region',
                                 'district_ID': 'dist',
                                 'agDev_district_ID': 'add',
                                 'tradAuthority_ID': 'ta',
                                 'ea_ID': 'ea',
                                 'ea_psu_ID': 'psu',
                                 'lastMajor_hhCultOwn_dum': 'n01', # (this question does not explicitly ask for the last MAJOR cropping season, but implicitly implies it)
                                 'lastMajor': 'n02', #1: 2002/03; 2: 2004/04 (this question does not explicitly ask for the last MAJOR cropping season, but implicitly implies it)
                                  },
                    'season': 'major',
    },
    
    
    'sec_o': { 'indexVars': { 
                            'hh_ID': 'case_id',
                            'hh_ID2': 'hhid',
                            'field_ID': np.NaN,
                            'plot_ID': 'plotid',
                            'crop': np.NaN,
                            'wave': np.NaN,
                              },
                    'dataVars': {
                                 'areaPlotReported': 'o05a',
                                 'areaPlotReported_unit': 'o05b', #1: acre; 2: ha; 3: sqm; 4: other
                                 'areaPlotReported_unit_other': 'o05both',
                                 'crop01': 'o08a',
                                 'crop02': 'o08b',
                                 'crop03': 'o08c',
                                 'crop04': 'o08d',
                                 'crop05': 'o08e',
                                 'crop01_other': 'o08aoth',
                                 'crop02_other': 'o08both',
                                 'crop03_other': 'o08coth',
                                 'crop04_other': 'o08doth',
                                 'crop05_other': 'o08eoth',
                                  },
                    'season': 'major',
    },

    ### crop codes: crop01 - crop05
    # LOCAL MAIZE . . 1
    # COMPOSITE MAIZE 2
    # HYBRID MAIZE. . 3
    # CASSAVA . . . . 4
    # SWEET POTATO. . 5
    # IRISH POTATO. . 6
    # GROUNDNUT . . . 7
    # GROUND BEAN (NZAMA). . . . 8
    # RICE. . . . . . 9
    # FINGER MILLET (MAWERE) . . .10
    # SORGHUM . . . .11
    # PEARL MILLET (MCHEWERE) . .12
    # BEAN. . . . . .13 
    # SOYABEAN. . . .14
    # PIGEONPEA . . .15 
    # BURLEY TOBACCO.16 
    # TOBACCO-OTHER .17
    # COTTON. . . . .18
    # SUGAR CANE. . .19
    # CABBAGE . . . .20
    # TANAPOSI. . . .21
    # NKHWANI . . . .22
    # THERERE/OKRA. .23
    # TOMATO. . . . .24
    # ONION . . . . .25
    # PEAS. . . . . .26
    # OTHER (SPEC.) .27    
    
    'sec_r': { 'indexVars': { 
                            'hh_ID': 'case_id',
                            'hh_ID2': 'hhid',
                            'field_ID': np.NaN,
                            'plot_ID': 'plotid',
                            'crop': np.NaN,
                            'wave': np.NaN,
                              },
                    'dataVars': {
                                 'areaPlotReported': 'r06a',
                                 'areaPlotReported_unit': 'r06b', #1: acre; 2: ha; 3: sqm; 4: other
                                 'areaPlotReported_unit_other': 'r06both',
                                 'crop01': 'r07a',
                                 'crop02': 'r07b',
                                 'crop03': 'r07c',
                                 'crop04': 'r07d',
                                 'crop05': 'r07e',
                                 'crop01_other': 'r07aoth',
                                 'crop02_other': 'r07both',
                                 'crop03_other': 'r07coth',
                                 'crop04_other': 'r07doth',
                                 'crop05_other': 'r07eoth',
                                  },
                    'season': 'minor',
    },

    ### crop codes: crop01 - crop05
    # LOCAL MAIZE . . 1
    # COMPOSITE MAIZE 2
    # HYBRID MAIZE. . 3
    # SWEET POTATO. . 5
    # IRISH POTATO. . 6
    # RICE. . . . . . 9
    # BEAN. . . . . .13
    # SUGAR CANE. . .19
    # CABBAGE . . . .20
    # TANAPOSI. . . .21
    # NKHWANI . . . .22
    # THERERE/OKRA. .23
    # TOMATO. . . . .24
    # ONION . . . . .25
    # PEAS. . . . . .26
    # OTHER (SPEC.) .27    
    
    
    'mod': { 'indexVars': { 
                            'hh_ID': '',
                            'field_ID': '',
                            'plot_ID': '',
                            'crop': np.NaN,
                            'wave': np.NaN,
                              },
                    'dataVars': {
                                 '': '',
                                 '': '',
                                 '': '',
                                 '': '',
                                 '': '',
                                  },
                    'season': np.NaN,
    },
    
    
    'mod': { 'indexVars': { 
                            'hh_ID': '',
                            'field_ID': '',
                            'plot_ID': '',
                            'crop': np.NaN,
                            'wave': np.NaN,
                              },
                    'dataVars': {
                                 '': '',
                                 '': '',
                                 '': '',
                                 '': '',
                                 '': '',
                                  },
                    'season': np.NaN,
    },
    
    
    'mod': { 'indexVars': { 
                            'hh_ID': '',
                            'field_ID': '',
                            'plot_ID': '',
                            'crop': np.NaN,
                            'wave': np.NaN,
                              },
                    'dataVars': {
                                 '': '',
                                 '': '',
                                 '': '',
                                 '': '',
                                 '': '',
                                  },
                    'season': np.NaN,
    },
    
    
}




### higher level shapefiles than needed
import geopandas as gpd
shapefile_MW_gpd = gpd.read_file('/home/ugrewer/Desktop/dhs_ipumsi_mw/mw1987_2010.shp')

shapefile_MW_gpd = gpd.read_file('/home/ugrewer/Desktop/geo2_mw1998/geo2_mw1998.shp')
shapefile_MW_gpd.plot()





##### define module-variable dictionary: 2010 wave
####################

modVar_dct_2010 = {
    
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


    'householdgeovariablesihs3': { 'indexVars': {'hh_ID': 'case_id',
                                'wave': np.NaN,
                                  },
                    'dataVars': {'lon': 'lon_modified',
                                  'lat': 'lat_modified',
                                  },
                    'season': np.NaN,
    },


    'hh_mod_a_filt': { 'indexVars': { 'hh_ID': 'case_id',
                            'crop': np.NaN,
                            'wave': np.NaN,
                              },
                    'dataVars': {
                                'region': np.NaN,
                                'district': 'hh_a01',
                                 'township': 'hh_a02b',
                                  },
                    'season': np.NaN,
    },


    # 'ag_mod_a_filt': { 'indexVars': { 'hh_ID': 'case_id',
    #                         'wave': np.NaN,
    #                           },
    #                 'dataVars': {
    #                              'town': 'hh_a02b',
    #                              # 'lastMajor': 'ag_c0a', # answers -> 1: 2009/10; 2: 2008/09 (copy of: module hh_mod_x, question hh_x02)
    #                              # 'lastMajor_hhCultOwn_dum': 'ag_c01', # (copy of: module hh_mod_x, question hh_x03)
    #                              '': '',
    #                              '': '',
    #                              '': '',
    #                               },
    #                 'season': np.NaN,
    # },


    # 'ag_mod_b': { 'indexVars': { 'hh_ID': 'case_id',
    #                         # 'field_ID': '',
    #                         # 'plot_ID': '',
    #                         'crop': 'ag_b0c',
    #                         'wave': np.NaN,
    #                           },
    #                 'dataVars': {
    #                             # 'hhCultivated_dum': 'ag_b0a', # see module ag_mod_g
    #                              # 'areaPlotReported': 'ag_b01a', # see module ag_mod_c
    #                              # 'areaPlotReported_unit': 'ag_b01b', # see module ag_mod_c
    #                              # 'harvestStart_month': 'ag_b05a', # see module ag_mod_g
    #                              # 'harvestEnd_month': 'ag_b05b', # see module ag_mod_g
    #                               },
    #                 'season': 'major',
    # },



    'ag_mod_c': { 'indexVars': { 'hh_ID': 'case_id',
                            'field_ID': np.NaN,
                            'plot_ID': 'ag_c00',
                            'crop': np.NaN,
                            'wave': np.NaN,
                              },
                    'dataVars': {
                                 'areaPlotReported': 'ag_c04a',
                                 'areaPlotReported_unit': 'ag_c04b',
                                  'areaPlotGPS': 'ag_c04c',
                                  },
                    'season': 'major',
    },


    'ag_mod_d': { 'indexVars': { 'hh_ID': 'case_id',
                            'field_ID': np.NaN,
                            'plot_ID': 'ag_d00',
                            'crop': np.NaN,
                            'wave': np.NaN,
                              },
                    'dataVars': {'field_usage': 'ag_d14',
                                'crop01': 'ag_d20a',
                                'crop02': 'ag_d20b',
                                'crop03': 'ag_d20c',
                                'crop04': 'ag_d20d',
                                'crop05': 'ag_d20e',
                                  },
                    'season': 'major',
    },
    

    'ag_mod_g': { 'indexVars': { 'hh_ID': 'case_id',
                            'field_ID': np.NaN,
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
                            'field_ID': np.NaN,
                            'plot_ID': 'ag_j00',
                            'crop': np.NaN,
                            'wave': np.NaN,
                              },
                    'dataVars': {'areaPlotReported': 'ag_j05a',
                                 'areaPlotReported_unit': 'ag_j05b',
                                 'areaPlotReported_unitOther': 'ag_j05b_os',
                                 'areaPlotGPS': 'ag_j05c', # in acres
                                  },
                    'season': 'minor',
    },
    

    'ag_mod_k': { 'indexVars': { 'hh_ID': 'case_id',
                            'field_ID': np.NaN,
                            'plot_ID': 'ag_k0a',
                            'crop': np.NaN,
                            'wave': np.NaN,
                              },
                    'dataVars': {
                                 'field_usage': 'ag_k15',
                                 'field_usage_other': 'ag_k15_os',
                                 'crop01': 'ag_k21a',
                                 'crop01_other': 'ag_k21a_os',
                                 'crop02': 'ag_k21b',
                                 'crop02_other': 'ag_k21b_os',
                                 'crop03': 'ag_k21c',
                                 'crop03_other': 'ag_k21c_os',
                                 'crop04': 'ag_k21d',
                                 'crop04_other': 'ag_k21d_os',
                                 'crop05': 'ag_k21e',
                                 'crop05_other': 'ag_k21e_os',
                                  },
                    'season': 'minor',
    },

    
    'ag_mod_m': { 'indexVars': { 'hh_ID': 'case_id',
                            'field_ID': np.NaN,
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
# AG-MODULE P: TREE / PERMANENT CROP PRODUCTION





##### define module-variable dictionary: 2016 wave
####################

modVar_dct_2016 = {
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
    'ag_mod_d': { 'indexVars': {'hh_ID': 'case_id',
                                'field_ID': 'gardenid',
                                'plot_ID': 'plotid',
                                'crop': np.NaN,
                                'wave': np.NaN,
                                  },
                    'dataVars': {
                        'field_usage': 'ag_d14',
                        'crop01': 'ag_d20a',
                        'crop02': 'ag_d20b',
                        'crop03': 'ag_d20c',
                        'crop04': 'ag_d20d',
                        'crop05': 'ag_d20e',
                        # 'irrigation_type': 'ag_d28a',
                        'planting_month': 'ag_d35_1a',
                        'planting_monthHalf': 'ag_d35_1b',
                                  },
                    'season': 'major',
    },
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
    'ag_mod_k': { 'indexVars': {'hh_ID': 'case_id',
                                'field_ID': 'gardenid',
                                'plot_ID': 'plotid',
                                'crop': np.NaN,
                                'wave': np.NaN,
                                  },
                    'dataVars': {
                                # 'field_ID_major_dum': 'ag_k01',
                                # 'field_ID_major': 'ag_k01b',
                                'crop01': 'ag_k21a',
                                'crop02': 'ag_k21b',
                                'crop03': 'ag_k21c',
                                'crop04': 'ag_k21d',
                                'crop05': 'ag_k21e',
                                'crop_other': 'ag_k21_oth',
                                'lastMinor_cult': 'ag_k36',
                                'planting_month': 'ag_k36_1a',
                                'planting_monthHalf': 'ag_k36_1b',
                                  },
                    'season': 'minor',
    },
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
    'householdgeovariablesihs4': { 'indexVars': {'hh_ID': 'case_id',
                                'wave': np.NaN,
                                  },
                    'dataVars': {'lon': 'lon_modified',
                                  'lat': 'lat_modified',
                                  },
                    'season': np.NaN,
    },
}





##### define module-variable dictionary: 2019 wave
####################

modVar_dct_2019 = {
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
    'ag_mod_d_modified': { 'indexVars': {'hh_ID': 'case_id',
                                'field_ID': 'gardenid',
                                'plot_ID': 'plotid',
                                'crop': np.NaN,
                                'wave': np.NaN,
                                  },
                    'dataVars': {'field_usage': 'ag_d14',
                                'crop01': 'ag_d20a',
                                'crop02': 'ag_d20b',
                                'crop03': 'ag_d20c',
                                'crop04': 'ag_d20d',
                                'crop05': 'ag_d20e',
                                'crop_other01': 'ag_d20_oth',
                                'crop_other02': 'ag_d20b_oth',
                                'planting_month': 'ag_d35_1a',
                                'planting_monthHalf': 'ag_d35_1b',
                                  },
                    'season': 'major',
    },
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
    'ag_mod_k': { 'indexVars': {'hh_ID': 'case_id',
                                'field_ID': 'gardenid',
                                'plot_ID': 'plotid',
                                'crop': np.NaN,
                                'wave': np.NaN,
                                  },
                    'dataVars': {
                                # 'field_ID_major_dum': 'ag_k01a',
                                # 'field_ID_major': 'ag_k01b',
                                'crop01': 'ag_k21a',
                                'crop02': 'ag_k21b',
                                'crop03': 'ag_k21c',
                                'crop04': 'ag_k21d',
                                'crop05': 'ag_k21e',
                                'crop_other01': 'ag_k21_oth',
                                'crop_other02': 'ag_k21b_oth',
                                'lastMinor_cult': 'ag_k36',
                                'planting_month': 'ag_k36_1a',
                                'planting_monthHalf': 'ag_k36_1b',
                                  },
                    'season': 'minor',
    },
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
    'householdgeovariables_ihs5': { 'indexVars': {'hh_ID': 'case_id',
                                'wave': np.NaN,
                                  },
                    'dataVars': {'lon': 'ea_lon_mod',
                                  'lat': 'ea_lat_mod',
                                  },
                    'season': np.NaN,
    },
}










### define dictionary for harmonization of crop-names: 2016 wave
cropNameHarmonize_dct_2016 = {
    'ag_mod_d': {'cropCols_lst': ['crop01', 'crop02', 'crop03', 'crop04', 'crop05'],
                 'mainCropCol': 'crop01',
        },
    'ag_mod_g': {'cropCols_lst': ['cropCode'],
                 'mainCropCol': 'cropCode',
        },
    'ag_mod_k': {'cropCols_lst': ['crop01','crop02','crop03','crop04','crop05','crop_other'],
                 'mainCropCol': 'crop01',
        },
    'ag_mod_m': {'cropCols_lst': ['cropCode'],
                 'mainCropCol': 'cropCode',
        },
}


### define dictionary for harmonization of crop-names: 2019 wave
cropNameHarmonize_dct_2019 = {
    'ag_mod_d_modified': {'cropCols_lst': ['crop01','crop02','crop03','crop04','crop05','crop_other01','crop_other02'], # additional variety information available in crop names here, if needed
         'mainCropCol': 'crop01',
        },
    'ag_mod_g': {'cropCols_lst': ['cropCode'],
         'mainCropCol': 'cropCode',
        },
    'ag_mod_k': {'cropCols_lst': ['crop01','crop02','crop03','crop04','crop05','crop_other01','crop_other02'],
         'mainCropCol': 'crop01',
        },
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




### wave- & module-specific pre-cleaning
####################################################################################################################
####################################################################################################################

### wave 2004, module : rename crops from numeric to string




### instantiate objects
####################################################################################################################
####################################################################################################################


### instatiate panel object
panel_MWI = Panel(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct)

### instatiate wave objects
MWI_2004 = SurveyWave(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2004, Path( str(data_folder_LSMS), '2004_2005/MWI_2004_IHS-II_v01_M_Stata8_DtaToCsvExport'), 'MWI_2004_IHS-II_v01_M', 'https://doi.org/10.48529/2ked-2t88', modVar_dct_2004, cropNameHarmonize_dct_2004 )
MWI_2010 = SurveyWave(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2010, Path( str(data_folder_LSMS), '2010_2011/MWI_2010_IHS-III_v01_M_STATA8_DtaToCsvExport'), 'MWI_2010_IHS-III_v01_M', 'https://doi.org/10.48529/w1jq-qh85', modVar_dct_2010, cropNameHarmonize_dct_2010 )
MWI_2016 = SurveyWave(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2016, Path( str(data_folder_LSMS), '2016_2017/MWI_2016_IHS-IV_v04_M_STATA14_DtaToCsvExport'), 'MWI_2016_IHS-IV_v04_M', 'https://doi.org/10.48529/g2p9-9r19', modVar_dct_2016, cropNameHarmonize_dct_2016 )
MWI_2019 = SurveyWave(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2019, Path( str(data_folder_LSMS), '2019_2020/MWI_2019_IHS-V_v05_M_Stata_DtaToCsvExport'), 'MWI_2019_IHS-V_v05_M', 'https://doi.org/10.48529/yqn3-zv74', modVar_dct_2019, cropNameHarmonize_dct_2019 )




### get list of modules
MWI_2016_module_lst = MWI_2016.modlue_lst
MWI_2019_module_lst = MWI_2019.modlue_lst


### harmonize and simplify cropnames
####################################################################################################################
####################################################################################################################

if __name__ == '__main__':


### merge modules into wave: 2016
####################################################################################################################
####################################################################################################################

    ### generate module-instances
    ##########
    MWI_2016_hh_mod_x = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2016, Path( str(data_path), 'LSMS/MWI/2016/data/MWI_2016_IHS-IV_v02_M_Stata_csvExport'), modVar_dct_2016, cropNameHarmonize_dct_2016, 'hh_mod_x' )
    MWI_2016_ag_mod_c = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2016, Path( str(data_path), 'LSMS/MWI/2016/data/MWI_2016_IHS-IV_v02_M_Stata_csvExport'), modVar_dct_2016, cropNameHarmonize_dct_2016, 'ag_mod_c' )
    MWI_2016_ag_mod_d = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2016, Path( str(data_path), 'LSMS/MWI/2016/data/MWI_2016_IHS-IV_v02_M_Stata_csvExport'), modVar_dct_2016, cropNameHarmonize_dct_2016, 'ag_mod_d' )
    MWI_2016_ag_mod_g = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2016, Path( str(data_path), 'LSMS/MWI/2016/data/MWI_2016_IHS-IV_v02_M_Stata_csvExport'), modVar_dct_2016, cropNameHarmonize_dct_2016, 'ag_mod_g' )
    MWI_2016_ag_mod_j = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2016, Path( str(data_path), 'LSMS/MWI/2016/data/MWI_2016_IHS-IV_v02_M_Stata_csvExport'), modVar_dct_2016, cropNameHarmonize_dct_2016, 'ag_mod_j' )
    MWI_2016_ag_mod_k = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2016, Path( str(data_path), 'LSMS/MWI/2016/data/MWI_2016_IHS-IV_v02_M_Stata_csvExport'), modVar_dct_2016, cropNameHarmonize_dct_2016, 'ag_mod_k' )
    MWI_2016_ag_mod_m = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2016, Path( str(data_path), 'LSMS/MWI/2016/data/MWI_2016_IHS-IV_v02_M_Stata_csvExport'), modVar_dct_2016, cropNameHarmonize_dct_2016, 'ag_mod_m' )
    MWI_2016_householdgeovariablesihs4 = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2016, Path( str(data_path), 'LSMS/MWI/2016/data/MWI_2016_IHS-IV_v02_M_Stata_csvExport'), modVar_dct_2016, cropNameHarmonize_dct_2016, 'householdgeovariablesihs4' )

    ### generate module-dataframes
    ##########
    MWI_2016_hh_mod_x_pd = MWI_2016_hh_mod_x.module_pd
    MWI_2016_ag_mod_c_pd = MWI_2016_ag_mod_c.module_pd
    MWI_2016_ag_mod_d_pd = MWI_2016_ag_mod_d.module_pd
    MWI_2016_ag_mod_g_pd = MWI_2016_ag_mod_g.module_pd
    MWI_2016_ag_mod_j_pd = MWI_2016_ag_mod_j.module_pd
    MWI_2016_ag_mod_k_pd = MWI_2016_ag_mod_k.module_pd
    MWI_2016_ag_mod_m_pd = MWI_2016_ag_mod_m.module_pd
    MWI_2016_householdgeovariablesihs4_pd = MWI_2016_householdgeovariablesihs4.module_pd

    ### consult index variables of each module
    ##########
    MWI_2016_hh_mod_x.indexVar_lst
    MWI_2016_ag_mod_c.indexVar_lst
    MWI_2016_ag_mod_d.indexVar_lst
    MWI_2016_ag_mod_g.indexVar_lst
    MWI_2016_ag_mod_j.indexVar_lst
    MWI_2016_ag_mod_k.indexVar_lst
    MWI_2016_ag_mod_m.indexVar_lst
    MWI_2016_householdgeovariablesihs4.indexVar_lst

    ### consult season of each module
    ##########
    MWI_2016_ag_mod_d.season
    MWI_2016_ag_mod_g.season
    MWI_2016_ag_mod_c.season
    MWI_2016_ag_mod_k.season
    MWI_2016_ag_mod_m.season
    MWI_2016_ag_mod_j.season
    MWI_2016_hh_mod_x.season
    MWI_2016_householdgeovariablesihs4.season


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



    ### save wave to disk
    ##########
    MWI_2016_pd.to_csv( Path( str(project_path), 'LSMS_MWI', 'MWI_2016_ingested.csv') )





### merge modules into wave: 2019
####################################################################################################################
####################################################################################################################


    ### generate Module-instances
    ##########
    MWI_2019_hh_mod_x = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2019, Path( str(data_path), 'LSMS/MWI/2019/data/MWI_2019_IHS-V_v04_M_Stata_csvExport'), modVar_dct_2019, cropNameHarmonize_dct_2019, 'hh_mod_x' )
    MWI_2019_ag_mod_c = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2019, Path( str(data_path), 'LSMS/MWI/2019/data/MWI_2019_IHS-V_v04_M_Stata_csvExport'), modVar_dct_2019, cropNameHarmonize_dct_2019, 'ag_mod_c' )
    MWI_2019_ag_mod_d_modified = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2019, Path( str(data_path), 'LSMS/MWI/2019/data/MWI_2019_IHS-V_v04_M_Stata_csvExport'), modVar_dct_2019, cropNameHarmonize_dct_2019, 'ag_mod_d_modified' )
    MWI_2019_ag_mod_g = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2019, Path( str(data_path), 'LSMS/MWI/2019/data/MWI_2019_IHS-V_v04_M_Stata_csvExport'), modVar_dct_2019, cropNameHarmonize_dct_2019, 'ag_mod_g' )
    MWI_2019_ag_mod_j = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2019, Path( str(data_path), 'LSMS/MWI/2019/data/MWI_2019_IHS-V_v04_M_Stata_csvExport'), modVar_dct_2019, cropNameHarmonize_dct_2019, 'ag_mod_j' )
    MWI_2019_ag_mod_k = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2019, Path( str(data_path), 'LSMS/MWI/2019/data/MWI_2019_IHS-V_v04_M_Stata_csvExport'), modVar_dct_2019, cropNameHarmonize_dct_2019, 'ag_mod_k' )
    MWI_2019_ag_mod_m = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2019, Path( str(data_path), 'LSMS/MWI/2019/data/MWI_2019_IHS-V_v04_M_Stata_csvExport'), modVar_dct_2019, cropNameHarmonize_dct_2019, 'ag_mod_m' )
    MWI_2019_householdgeovariables_ihs5 = Module(country, wave_lst, panel_indexVars_lst, cropNameConvert_dct, 2019, Path( str(data_path), 'LSMS/MWI/2019/data/MWI_2019_IHS-V_v04_M_Stata_csvExport'), modVar_dct_2019, cropNameHarmonize_dct_2019, 'householdgeovariables_ihs5' )


    ### generate module-dataframes
    ##########
    MWI_2019_hh_mod_x_pd = MWI_2019_hh_mod_x.module_pd
    MWI_2019_ag_mod_c_pd = MWI_2019_ag_mod_c.module_pd
    MWI_2019_ag_mod_d_modified_pd = MWI_2019_ag_mod_d_modified.module_pd
    MWI_2019_ag_mod_g_pd = MWI_2019_ag_mod_g.module_pd
    MWI_2019_ag_mod_j_pd = MWI_2019_ag_mod_j.module_pd
    MWI_2019_ag_mod_k_pd = MWI_2019_ag_mod_k.module_pd
    MWI_2019_ag_mod_m_pd = MWI_2019_ag_mod_m.module_pd
    MWI_2019_householdgeovariables_ihs5_pd = MWI_2019_householdgeovariables_ihs5.module_pd

    ### consult index variables of each module
    ##########
    MWI_2019_hh_mod_x.indexVar_lst
    MWI_2019_ag_mod_c.indexVar_lst
    MWI_2019_ag_mod_d_modified.indexVar_lst
    MWI_2019_ag_mod_g.indexVar_lst
    MWI_2019_ag_mod_j.indexVar_lst
    MWI_2019_ag_mod_k.indexVar_lst
    MWI_2019_ag_mod_m.indexVar_lst
    MWI_2019_householdgeovariables_ihs5.indexVar_lst

    ### consult season of each module
    ##########
    MWI_2019_ag_mod_d_modified_pd.season
    MWI_2019_ag_mod_g.season
    MWI_2019_ag_mod_c.season
    MWI_2019_ag_mod_k.season
    MWI_2019_ag_mod_m.season
    MWI_2019_ag_mod_j.season
    MWI_2019_hh_mod_x.season
    MWI_2019_householdgeovariables_ihs5.season



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



    ### save wave to disk
    ##########
    MWI_2019_pd.to_csv( Path( str(project_path), 'LSMS_MWI', 'MWI_2019_ingested.csv') )







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
    panel_MWI_pd.to_csv( Path( str(project_path), 'LSMS_MWI', 'MWI_panel_ingested.csv' ), index=False )




### anecdotal testing
####################################################################################################################
####################################################################################################################


    panel_MWI.country
    MWI_2016.wave
    MWI_2016_indexVars_tpl = MWI_2016.indexVars_tpl
