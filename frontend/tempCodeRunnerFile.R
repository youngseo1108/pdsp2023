###################################################################################################
# Author: xx
# Project: xx
# File: init__.R
# Description: project initialisation
###################################################################################################
# Input: config.R
# Output: front end running logic
###################################################################################################

# install necessary packages --- it would be better to create a function
library(shiny)
library(httr)
library(dplyr)
library(jsonlite)
# sourcing necessary files ----
source("C:/GitHub/pdsp2023/frontend/src/config.R")
source("C:/GitHub/pdsp2023/frontend/src/run_shiny.R")
#source("src/config.R")
#source("src/run_shiny.R")

# running the front-end ---
run_shiny_front(external_ip, port)