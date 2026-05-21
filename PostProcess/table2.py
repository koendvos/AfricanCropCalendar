
### package imports
##########################################################
import os
import socket
import sys
from pathlib import Path

import numpy as np
import pandas as pd

import datetime





# load dataset
lsms_pd = pd.read_csv("../AfricanCropCalendar_cleanCropname.csv")


### correct errors in mixed string-integer variables (trailing .0; whitespaces; etc.)
#####

# clean identifier variables
id_vars = ["hhID", "fieldID", "plotID"]

for var in id_vars:

    lsms_pd[var] = (
        lsms_pd[var]

        # preserve missing values properly
        .astype("string")

        # remove leading/trailing whitespace
        .str.strip()

        # remove trailing ".0" introduced by Excel/R numeric conversion
        .str.replace(r"\.0$", "", regex=True)
    )





### table2
table2 = lsms_pd.groupby(["country", "dataset_name"], as_index=False).agg(
    # crop=("crop", "nunique"),
    adm1=("adm1", "nunique"),
    adm2=("adm2", "nunique"),
    adm3=("adm3", "nunique"),
    adm4=("adm4", "nunique"),
    hhID=("hhID", "nunique"),
    plotID=("plotID", "count"),
    crop_simplified=("crop_simplified", "nunique"),

    planting_month_valid_pct=(
        "planting_month",
        lambda x: round((1 - x.isna().mean()) * 100, 1)
    ),

    harvest_month_begin_valid_pct=(
        "harvest_month_begin",
        lambda x: round((1 - x.isna().mean()) * 100, 1)
    ),

    harvest_month_end_valid_pct=(
        "harvest_month_end",
        lambda x: round((1 - x.isna().mean()) * 100, 1)
    ),
)

# reformat year
table2["dataset_name"] = table2["dataset_name"].str.split("_").str[1]
table2["dataset_name"] = table2["dataset_name"].replace("2010-2013", "2013")

# assign new column names
new_cols = [
    "Country", 
    "Year", 
    "Adm level 1",
    "Adm level 2",
    "Adm level 3",
    "Adm level 4",
    "Households",
    "Plots",
    "Crops",
    "Planting month",
    "Start of harvest",
    "End of harvest",
]
table2.columns = new_cols
table2 = table2.sort_values(["Country", "Year"])
table2.to_csv("table2.csv", index=False)



#### country aggregate
table2bis = lsms_pd.groupby(["country"], as_index=False).agg(
    adm1=("adm1", "nunique"),
    adm2=("adm2", "nunique"),
    adm3=("adm3", "nunique"),
    adm4=("adm4", "nunique"),
    hhID=("hhID", "nunique"),
    plotID=("plotID", "count"),
    # crop=("crop", "nunique"),
    crop_simplified=("crop_simplified", "nunique"),

    planting_month_valid_pct=(
        "planting_month",
        lambda x: round((1 - x.isna().mean()) * 100, 1)
    ),

    harvest_month_begin_valid_pct=(
        "harvest_month_begin",
        lambda x: round((1 - x.isna().mean()) * 100, 1)
    ),

    harvest_month_end_valid_pct=(
        "harvest_month_end",
        lambda x: round((1 - x.isna().mean()) * 100, 1)
    ),
)


# assign new column names
new_cols = [
    "Country", 
    "Adm level 1",
    "Adm level 2",
    "Adm level 3",
    "Adm level 4",
    "Households",
    "Plots",
    "Crops",
    "Planting month ",
    "Start of harvest ",
    "End of harvest ",
]
table2bis.columns = new_cols
table2bis = table2bis.sort_values(["Country"])
table2bis.to_csv("table2bis.csv", index=False)

#### dataset aggregate
table2all = pd.DataFrame([{
    "adm1": lsms_pd["adm1"].nunique(),
    "adm2": lsms_pd["adm2"].nunique(),
    "adm3": lsms_pd["adm3"].nunique(),
    "adm4": lsms_pd["adm4"].nunique(),
    "hhID": lsms_pd["hhID"].nunique(),
    "plotID": lsms_pd["plotID"].count(),
    # "crop": lsms_pd["crop"].nunique(),
    "crop_simplified": lsms_pd["crop_simplified"].nunique(),

    "planting_month_valid_pct":
        round((1 - lsms_pd["planting_month"].isna().mean()) * 100, 1),

    "harvest_month_begin_valid_pct":
        round((1 - lsms_pd["harvest_month_begin"].isna().mean()) * 100, 1),

    "harvest_month_end_valid_pct":
        round((1 - lsms_pd["harvest_month_end"].isna().mean()) * 100, 1),
}])

table2all.to_csv("table2all.csv", index=False)