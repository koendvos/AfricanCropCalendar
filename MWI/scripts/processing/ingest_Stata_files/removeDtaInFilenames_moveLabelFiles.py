# -*- coding: utf-8 -*-
"""
Created on Tue Mar 10 11:27:09 2020

@author: uqugrewe
"""


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

# print all environmental variables
for envVar_name, envVar_path in os.environ.items():
    print(envVar_name, envVar_path)


### access project folder path (from environmental variable)
project_path = os.environ['growPeriodMWI']


# # add project directory to system path (note: system path expects only strings to be added - not pathlib_objects)
# if str(project_path) not in sys.path:
#     sys.path.append( str(project_path) )

# set working directory to project path
os.chdir(project_path)

# import major path locations
from scripts.defPaths import *







### revove DTA in filenames & move label files to separate directories
####################################################################################################################
####################################################################################################################

### define list of dta-exported csv-files
dtaCSV_files_lst = []

# loop over LSMS data directory
for rootdirs1, subdirs1, files1 in os.walk( data_folder_LSMS ):
    #print(rootdirs1)

    ### filter: consider DtaToCsvExport-directories only
    if rootdirs1.endswith('DtaToCsvExport'):

        wave_data_dir = rootdirs1
        print('Parent-directory of wave has been identified as:', wave_data_dir, '\n')


        # loop over files in data directories
        for files2 in os.listdir(wave_data_dir):
            print(files2)


            # filter: consider Stata-exported files only
            if files2.endswith('.dta.csv') or files2.endswith('.dta_labels.csv'):
                print('Csv-file has been identified as:', os.path.join(wave_data_dir, files2))
                dtaCSV_files_lst.append( os.path.join(wave_data_dir, files2) )





### strip 'dta' from filename
#######################

#loop over all dta-exported csv-files
for dta_csv_file in dtaCSV_files_lst:
    print('dta_csv_file:', dta_csv_file)

    # strip 'dta' from filename
    new_name_tmp = dta_csv_file.replace('.dta', '')
    # convert new filename to lowercase
    new_name_tmp = os.path.join( os.path.dirname(new_name_tmp), os.path.basename(new_name_tmp).lower()  )
    # rename file
    os.rename( dta_csv_file, new_name_tmp )






### move 'label'-files to separate directory
#######################


# loop over LSMS data directory
for rootdirs1, subdirs1, files1 in os.walk( data_folder_LSMS ):
    #print(rootdirs1)

    ### filter: consider DtaToCsvExport-directories only
    if rootdirs1.endswith('DtaToCsvExport'):

        wave_data_dir = rootdirs1
        print('Parent-directory of wave has been identified as:', wave_data_dir, '\n')

        # loop over files in DtaToCsvExport-directories
        for files2 in os.listdir(wave_data_dir):

            # filter: consider label-files only
            if files2.endswith('_labels.csv'):
                print('Label-file has been identified as:', os.path.join(wave_data_dir, files2))



                # generate labels-folder
                new_dir_tmp = os.path.join(wave_data_dir, r'labels')
                os.makedirs(new_dir_tmp, exist_ok = True) # if directory existed already, no error message is generated
    
                # move labels file to separate folder
                os.replace( os.path.join(wave_data_dir, files2), os.path.join(new_dir_tmp, files2) )




#shutil.move("path/to/current/file.foo", "path/to/new/destination/for/file.foo")
#os.replace("path/to/current/file.foo", "path/to/new/destination/for/file.foo")
