## Prototyping Data Science Product 2023
Create a web-app that helps the Network Planner department of SWISS in designing optimal network planning<br/>
Publisher: Backend - Youngseo Kim, Tianjiao Liu / Frontend - Insun Lee, Guoping He


### Structure
```bash
├───backend
│   ├───dataset
│   │   ├───airport-codes_csv.csv
│   │   ├───dataprep_v2.csv
│   │   └───final_v2.csv
│   ├───data_engineering
│   │   ├───backend_1129.py
│   │   └───PostgreSql_accuracy.ipynb
│   ├───ML
│   │   ├───multi_rf.ipynb
│   │   └───rf.ipynb
│   ├───preprocessing
│   │   ├───Prepro_kaggle.ipynb
│   │   └───Prepro_v2.ipynb
│   └───requirements.txt
├───frontend
│   ├───airplane.png
│   ├───final_no_pie.R
│   └───world_country.csv
├───.gitignore
└───README.md
```


### Explanation of files
1. backend
* dataset
  * airport-codes_csv.csv: a CSV file of labelling country codes to numbers
  * (deleted) dataprep_v2.csv: preprocessed data
  * (deleted) final_v2.csv: preprocessed data with indexes

* data_engineering
  * backend_1129.py: connect the database server to the backend
  * PostgreSql_accuracy.ipynb: a script calculating the accuracy of the model

* ML
  * multi_rf.ipynb: multioutput regressor + random forest model predicting TOT_pax, paxe, market_share and attaching indexes after the prediction
  * rf.ipynb: random forest model predicting market_share

* preprocessing
  * Prepro_kaggle.ipynb: a script preprocessing the Kaggle dataset for the Kaggle competition
  * Prepro_v2.ipynb: a script preprocessing the original dataset

* requirements.txt: the list of necessary packages to run backend/data_engineering/backend_1129.py

2. frontend
  * airplane.png: an image of an aeroplane for the map in the UI
  * final_no_pie.R: a frontend script for the UI, including the map, the recommendation table, accuracy & a predicted market_share/TOT_pax and other information
  * world_country.csv: a file containing geographical information of countries to show routes on the map

3. .gitignore
4. README.md


### Required packages
1. Backend
```python
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error
from sklearn.multioutput import MultiOutputRegressor
from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import RandomizedSearchCV
from sklearn.ensemble import ExtraTreesRegressor
import warnings
import seaborn as sns
import matplotlib.pyplot as plt
from pprint import pprint
import psycopg2
import sqlite3
from io import StringIO
import numpy as np
from flask import Flask, jsonify, request
```

2. Frontend
```R
install.packages("shiny")
install.packages("shinyjs")
install.packages("dplyr")
install.packages("shinydashboard")
install.packages("leaflet")
install.packages("plotly")
install.packages("httr")

library(shiny)
library(shinyjs)
library(dplyr)
library(shinydashboard)
library(leaflet)
library(plotly)
library(httr)
```
