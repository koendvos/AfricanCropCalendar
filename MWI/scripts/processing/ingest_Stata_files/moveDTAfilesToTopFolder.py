# -*- coding: utf-8 -*-

### package imports
####################################################################################################################
####################################################################################################################
import sys
import os
import socket
from pathlib import Path
import shutil

import time
import datetime

import pandas as pd
import numpy as np




### setup
####################################################################################################################
####################################################################################################################

# # identify user (platform-independent)
# getpass.getuser()
# # identify home-directory (platform-independent)
# os.path.expanduser("~")

# # print all environmental variables
# for envVar_name, envVar_path in os.environ.items():
#     print(envVar_name, envVar_path)

### access project folder path (from environmental variable)
project_path = os.environ['growPeriodMWI']


# # add project directory to system path (note: system path expects only strings to be added - not pathlib_objects)
# if str(project_path) not in sys.path:
#     sys.path.append( str(project_path) )

# set working directory to project path
os.chdir(project_path)

# import major path locations
from scripts.defPaths import *





### Move dta-files to top-level folder of Stata-folder for each wave
####################################################################################################################
####################################################################################################################

print('Attention: This script expects that all Stata-dta folders have been unzipped already.')

# loop over LSMS data directory
for rootdirs1, subdirs1, files1 in os.walk( data_folder_LSMS ):
    # print(rootdirs1)

    ### loop over wave directories
    if ( 'stata' in rootdirs1.lower() ) and ( len( rootdirs1.split('\\') ) == 12 ) and ( 'DtaToCsvExport' not in rootdirs1 ):
    # if ( 'stata' in rootdirs1.lower() ) and ( len( rootdirs1.split('\\') ) == 9 ):

        wave_data_dir = rootdirs1
        print('Parent-directory of wave has been identified as:', wave_data_dir, '\n\n')


        ### loop over items in wave folders
        for level_1_content in os.listdir(wave_data_dir):

            # test if level_1_content is a folder
            if os.path.isdir( os.path.join(wave_data_dir,level_1_content) ):
                print('\nSub-folder level 1:', level_1_content)



                ### delete undesired folders (duplicate data, etc.)
                ##########
                # delete separate folder that exclusively contains panel observations (2010_2011)
                if level_1_content == 'Panel':
                    shutil.rmtree( os.path.join(wave_data_dir,level_1_content) )
                    continue


                ### loop through content in level_1_content
                ##########
                for level_2_content in os.listdir( os.path.join(wave_data_dir,level_1_content) ):

                    # test if level_2_content is a folder
                    if os.path.isdir(os.path.join(wave_data_dir, level_1_content, level_2_content)):
                        print('Sub-folder level 2:', level_2_content)

                        ### loop through content in level_2_content
                        ##########
                        for level_3_content in os.listdir(os.path.join(wave_data_dir, level_1_content, level_2_content)):


                            # test if level_3_content is a folder
                            if os.path.isdir(os.path.join(wave_data_dir, level_1_content, level_2_content, level_3_content)):
                                print('Sub-folder level 3:', level_3_content)

                                # loop through content in level_3_content
                                ##########
                                for level_4_content in os.listdir( os.path.join(wave_data_dir, level_1_content, level_2_content, level_3_content) ):
                                    print('Level 4 content is:', level_4_content)

                                    ### move items in sub-folder level 3 to wave-folder
                                    os.replace(os.path.join(wave_data_dir, level_1_content, level_2_content, level_3_content, level_4_content), os.path.join(wave_data_dir, level_4_content))

                            ### move items in sub-folder level 2 to wave-folder
                            else:
                                os.replace(os.path.join(wave_data_dir, level_1_content, level_2_content, level_3_content), os.path.join(wave_data_dir, level_3_content))

                    ### move items in sub-folder level 1 to wave-folder
                    else:
                        os.replace(os.path.join(wave_data_dir, level_1_content, level_2_content), os.path.join(wave_data_dir, level_2_content))
