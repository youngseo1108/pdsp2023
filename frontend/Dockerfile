# Base image https://hub.docker.com/u/rocker/
FROM rocker/r-base:latest

WORKDIR /code

## copy files
COPY ./init__.R /code/init__.R
COPY ./src /code/src

## install R-packages
RUN apt update && apt install -y libcurl4-openssl-dev libssl-dev
RUN R -e "install.packages(c('shiny', 'httr', 'dpylr', 'jsonlite', 'leaflet', 'ggmap'), repos='https://cran.rstudio.com/')"

EXPOSE 3838
# specify 
# CMD ["R", "-e", "shiny::runApp('/code/init__.R', host='35.240.13.23', port=8080)"]
# CMD ["R", "-e", "shiny::runApp('/code/init__.R', host='127.0.0.1', port=3838)"]