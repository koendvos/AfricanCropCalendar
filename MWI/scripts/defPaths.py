#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Apr  6 16:14:28 2022

@author: ugrewer

Define paths of main directories
"""


### package and module imports
##########################################################
import os
import socket
import sys
from pathlib import Path
import numpy as np



### setup
####################################################################################################################
####################################################################################################################

### access project folder path (from environmental variable)
project_path = os.environ['growPeriodMWI']


# # add project directory to system path (note: system path expects only strings to be added - not pathlib_objects)
# if str(project_path) not in sys.path:
#     sys.path.append( str(project_path) )

# set working directory to project path
os.chdir(project_path)



### Define paths of main directories
##########################################################

# define LSMS parent-directory (raw data)
data_folder_LSMS = os.path.join(project_path, 'rawData')


if __name__ == '__main__':
    # print all system paths
    print('\n***** System paths:\n', sys.path)

    # print path of active python interpreter
    print('\n***** Paths of active python interpreter:\n', sys.executable)

    # print python version
    print('\n***** Python version:\n', sys.version)

    # print working directory
    print('\n***** Working directory:\n', os.getcwd())

    # print working directory
    print('\n***** Project directory:\n', project_path)

     # print working directory
    print('\n***** LSMS-data directory:\n', data_folder_LSMS)


