# Load packages
library(shiny)
library(dplyr)
library(DT)
library(tibble)
library(shinyWidgets)
library(lubridate)
library(bslib)
library(readxl)
library(brms)
library(shinyjs)
library(htmltools)
library(countrycode)
library(shinycssloaders)

# Load models and data
load("model_1to15.RData")
load("profiles_data.RData")
load("data_1to15.RData")
