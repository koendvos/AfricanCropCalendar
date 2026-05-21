# -*- coding: utf-8 -*-
"""
Created on Sun Mar 24 16:45:00 2024

@author: U8017882
"""

### package and module imports
##########################################################
import os
import socket
import sys
from pathlib import Path
import shutil
import glob
import numpy as np
import subprocess



#######################################################################
### Define the project directory and set it as working directory
#######################################################################
project_path = os.environ['growPeriodMWI']

# set working directory to project path
os.chdir(project_path)

# import major path locations
from scripts.defPaths import *



########################################################################
### Convert dta to csv (Note: This requires STATA. Exporting dta files allows to extract variable-labels that are not available in csv-files from the LSMS-download page.)
#######################################################################

### move dta-files to top-level folder of Stata-folder for each wave
##########
import scripts.processing.ingest_Stata_files.moveDTAfilesToTopFolder



### export LSMS files from DTA to CSV format (Note: this requires STATA)
##########

# define path of STATA executable
stataEXE_path="/usr/local/stata18/xstata"
# define path of STATA do-file
doFile_exportStataToCsv_path = os.path.join( project_path, 'processing', 'ingest_Stata_files', 'exportStataToCsv_Linux.do')
# run STATA do-file
subprocess.run( [stataEXE_path, 'do', doFile_exportStataToCsv_path] )



### manually export a module with a problematic column from dta to csv (Note: this requires STATA)
##########

# define path of STATA do-file
doFile_exportProblemModule_path = os.path.join( project_path, 'processing', 'ingest_Stata_files', 'manualCSVexport_2019_ag_mod_d.do')

# run STATA do-file
subprocess.run( [stataEXE_path, 'do', doFile_exportProblemModule_path] )

# delete incorrectly formatted module
problemModule_path = os.path.join( data_folder_LSMS, '2019_2020', 'MWI_2019_IHS-V_v05_M_Stata_DtaToCsvExport', 'ag_mod_d.dta.csv')
if os.path.isfile(problemModule_path):
    os.remove(problemModule_path)



### remove 'dta' from filenames & move label files to separate folder
##########
import scripts.processing.ingest_Stata_files.removeDtaInFilenames_moveLabelFiles



########################################################################
### Ingest and clean csv-files
#######################################################################

# ingest csv-files of LSMS data
import scripts.processing.ingest_csv_files.LSMS_ingest

# clean LSMS dataframes
import scripts.processing.LSMS_clean




########################################################################
### Convert data into harmonized format
#######################################################################

# harmonize LSMS dataframe: convert into harmonized data-format
import scripts.processing.LSMS_harmonize




########################################################################
### Generate metadata
#######################################################################
import scripts.processing.LSMS_metadata




########################################################################
### Copy harmonised files to overall results folder ("out")
#######################################################################

# list of final dataset- and metadata-files
resultsFiles_lst = glob.glob( os.path.join(project_path, 'scripts', 'LSMS_MWI_harmonized', '*') )

# path to overall results folder 
outFolder_path = os.path.join( os.path.dirname(project_path), 'out')


# loop over results-files
for resultsFile_srcPath in resultsFiles_lst:
    
    # define destination file-path
    resultsFile_dstPath = os.path.join( outFolder_path, os.path.basename(resultsFile_srcPath) )

    # copy each file to overall results folder (overwriting existing)
    shutil.copy2(resultsFile_srcPath, resultsFile_dstPath)




