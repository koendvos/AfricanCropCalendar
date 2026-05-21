# -*- coding: utf-8 -*-
"""
Created on Fri Jan  9 20:15:34 2026

@author: U8017882
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

# load harmonized panel dataset
panel_pd = pd.read_csv( Path( str(project_path), 'scripts', 'LSMS_MWI_harmonized', 'MWI_allWaves.csv') )


panel_pd.columns.to_list()

# plot count
panel_pd[['hhID','fieldID','plotID']].drop_duplicates().shape[0]


# household count
len(panel_pd['hhID'].dropna().unique())

# household count by wave
panel_pd.groupby('dataset_name')['hhID'].nunique()




