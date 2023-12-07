# Install necessary packages if not already installed
if (!require("shiny")) install.packages("shiny")
if (!require("shinyjs")) install.packages("shinyjs")
if (!require("dplyr")) install.packages("dplyr")
if (!require("shinydashboard")) install.packages("shinydashboard")
if (!require("leaflet")) install.packages("leaflet")
if (!require("plotly")) install.packages("plotly")
if (!require("httr")) install.packages("httr")

# Load the required libraries
library(shiny)
library(shinyjs)
library(dplyr)
library(shinydashboard)
library(leaflet)
library(plotly)
library(httr)

# Define custom_icon function
customIcon <- function(iconUrl, iconSize) {
  makeIcon(
    iconUrl = iconUrl,
    iconWidth = iconSize[1], iconHeight = iconSize[2],
    iconAnchorX = iconSize[1]/2, iconAnchorY = iconSize[2]/2
  )
}

# Read the world_country.csv file
world_data <- read.csv("world_country.csv")

# Extract unique country codes from the data
country_codes <- sort(unique(world_data$country_code))

# Create a Shiny app
ui <- dashboardPage(
  dashboardHeader(
    title = "Flight Dashboard",
    titleWidth = 200,
    tags$li(class = "dropdown",
      tags$style(HTML(".main-header { background-color: #8B0000; }"))
    )
  ),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Itinerary Overview", tabName = "overview")
    ),
    tags$style(
      HTML(".main-sidebar { background-color: #8B0000; }")
    ),
    collapsed = TRUE  # Initially collapsed
  ),
  dashboardBody(
    tags$style(HTML("body, .main-sidebar, 
      .right-side, .wrapper { background-color: #8B0000; }")),
    tabItems(
      tabItem(tabName = "overview",
        fluidRow(
          box(
            title = "Itinerary Overview",
            status = "primary",
            solidHeader = TRUE,
            width = 4,
            selectInput("departure_day", "Departure Day:", choices = NULL),
            selectInput("origin_country", "Origin Country", choices = NULL),
            selectInput("dest_country", "Destination Country", choices = NULL),
            actionButton("plot_route", "Search", style = "color: #fff; background-color: #FF0000;"),
          ),
          column(6, align = "center",
            style = "padding: 13px; border-rounded bg-lightgray map-container",
            leafletOutput("flight_map")
          )
        ),
        fluidRow(
          column(6,
            box(
              title = "Total Passengers",
              status = "primary",
              solidHeader = TRUE,
              width = NULL,
              verbatimTextOutput("total_passengers"),
              style = "margin-top: 40px; margin-bottom: 20px;"
            ),
          ),
          column(6,
            box(
              title = "Accuracy",
              status = "primary",
              solidHeader = TRUE,
              width = NULL,
              verbatimTextOutput("accuracy1"),
              style = "margin-top: 40px; margin-bottom: 20px;"
            )
          ),
          style = "margin-bottom: 20px;"
        ),
        fluidRow(
          box(
            title = "Recommendations",
            status = "primary",
            solidHeader = TRUE,
            width = 12,  # Adjusted to take up the full width
            dataTableOutput("recommendations"),
            style = "margin-top: 15px;"
          )
        ),
        fluidRow(
          box(
            title = "Detour",
            status = "primary",
            solidHeader = TRUE,
            width = 4,
            verbatimTextOutput("detour")
          ),
          box(
            title = "Stops",
            status = "primary",
            solidHeader = TRUE,
            width = 4,
            verbatimTextOutput("stops")
          ),
          box(
            title = "Distance",
            status = "primary",
            solidHeader = TRUE,
            width = 4,
            verbatimTextOutput("Distance")
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {
  map_data <- reactiveValues(map = NULL)
  origin_coords <- reactiveValues(longitude = NULL, latitude = NULL)
  dest_coords <- reactiveValues(longitude = NULL, latitude = NULL)
  chart <- reactiveValues(org_count = NULL, des_count = NULL)
  ip_address <- "http://35.228.60.62:5000" # "http://External_backend_server_IP:5000"

  # Fetch dynamic choices from the backend
  observe({  # departure day
    backend_url <- paste(ip_address, "/get_depDay", sep = "")
    departure_days <- req(httr::GET(url = backend_url))
    departure_days <- httr::content(departure_days, "text")
    departure_days <- jsonlite::fromJSON(departure_days)
    depDay_data <- data.frame(Departure_Days = as.numeric(unlist(departure_days)))
    depDay_data <- depDay_data[order(depDay_data$Departure_Days),, drop = FALSE]
    day_names <- c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
    depDay_data$Departure_Days <- day_names[depDay_data$Departure_Days]
    # print(depDay_data)
    updateSelectInput(session, "departure_day",
                      choices = depDay_data$Departure_Days,
                      selected = depDay_data$Departure_Days[1])
  })
  
  observe({  # original country
    backend_url <- paste(ip_address, "/get_Orig_s", sep = "")
    origin_data <- req(httr::GET(url = backend_url))
    # print(backend_url)
    origin_data <- httr::content(origin_data, "text")
    origin_data <- jsonlite::fromJSON(origin_data)
    origin_countries <- data.frame(Origin_Countries = unlist(origin_data))
    origin_countries <- origin_countries[order(origin_countries$Origin_Countries), , drop = FALSE]
    # print(origin_countries)
    updateSelectInput(session, "origin_country",
                      choices = origin_countries,
                      selected = origin_countries[1])
  })
  
  observeEvent(input$origin_country, {
    shinyjs::disable("origin_country")  # Disable the input during the async request
    # print(input$origin_country)
    backend_url <- paste(ip_address, "/get_Dest_s/", input$origin_country, sep = "")
    req_data <- req(httr::GET(url = backend_url))
    # print(str(req_data))

    if (http_type(req_data) == "application/json") {
      req_data <- httr::content(req_data, "text")
      tryCatch({
        dest_data <- jsonlite::fromJSON(req_data)
        # print("response")
        # print(str(dest_data))
        dest_countries <- dest_data
        updateSelectInput(session, "dest_country",
                          choices = dest_countries,
                          selected = dest_countries[1])
      }, error = function(e) {
        print(paste("Error parsing JSON:", e$message))
      })
    } else {
      print("Unexpected content type. Expected application/json.")
    }
    shinyjs::enable("origin_country")
  })

  observeEvent(input$plot_route, {
    if (!is.null(input$origin_country) && !is.null(input$dest_country)) {
      filtered_origin_entries <- world_data[world_data$country_code == input$origin_country,]
      filtered_dest_entries <- world_data[world_data$country_code == input$dest_country,]
      filtered_origin_entries <- filtered_origin_entries[complete.cases(filtered_origin_entries[, c("latitude", "longitude")]), ]
      filtered_dest_entries <- filtered_dest_entries[complete.cases(filtered_dest_entries[, c("latitude", "longitude")]), ]
      # print(filtered_origin_entries)
      # print(filtered_dest_entries)

      chart$org_count <- input$origin_country
      chart$des_count <- input$dest_country
      # print(chart$org_count)
      # print(chart$des_count)

      # Recommendation table
      backend_url_recommendation <- paste(ip_address, "/get_recommendation?Orig_s=", chart$org_count, "&Dest_s=", chart$des_count, sep = "")
      # print(backend_url_recommendation)
      data_recommendation <- req(httr::GET(url = backend_url_recommendation))
      data_recommendation <- httr::content(data_recommendation, "text")
      data_recommendation <- jsonlite::fromJSON(data_recommendation)
      dummy_data <- data.frame(
        Departure.hour = data_recommendation$Dephours,
        Arrival.hour = data_recommendation$Arrhours,
        Elapsed.time = data_recommendation$Elptime,
        Connection.time = data_recommendation$Connection_time,
        Market.Share = data_recommendation$Market_share,
        Option = data_recommendation$Option
      )
      output$recommendations <- renderDataTable({ dummy_data })

      # Accuracy and total passengers
      backend_url_results <- paste(ip_address, "/results?Orig_s=", chart$org_count, "&Dest_s=", chart$des_count, sep = "")
      pred_data <- req(httr::GET(url = backend_url_results))
      pred_data <- httr::content(pred_data, "text")
      pred_data <- jsonlite::fromJSON(pred_data)
      output$accuracy1 <- renderText(paste("Accuracy:", round(pred_data$Accuracy * 100, digits = 2), "%"))
      output$total_passengers <- renderText(paste("TOT_pax:", pred_data$TOT_pax))

      # other info
      backend_url_other <- paste(ip_address, "/other?Orig_s=", chart$org_count, "&Dest_s=", chart$des_count, sep = "")
      other_data <- req(httr::GET(url = backend_url_other))
      other_data <- httr::content(other_data, "text")
      other_data <- jsonlite::fromJSON(other_data)
      output$detour <- renderText(other_data$Detour)
      output$stops <- renderText(other_data$Stops)
      output$Distance <- renderText(paste(other_data$Distance, "km"))

      if (nrow(filtered_origin_entries) > 0) {
        origin_country_code <- filtered_origin_entries[1, "country_code"]
        origin_coords$latitude <- filtered_origin_entries[1, "latitude"]
        origin_coords$longitude <- filtered_origin_entries[1, "longitude"]
        if (!is.na(origin_coords$latitude) && !is.na(origin_coords$longitude)) {
          map <- leaflet() %>%
            addTiles() %>%
            setView(lng = origin_coords$longitude, lat = origin_coords$latitude, zoom = 5) %>%
            addMarkers(lng = origin_coords$longitude, lat = origin_coords$latitude, popup = input$origin_country)
          map_data$map <- map
          print(paste("Origin Country Code:", origin_country_code))
          print(paste("Origin Coordinates:", paste(origin_coords$latitude, origin_coords$longitude, collapse = ", ")))
        } else {
          print("Please select a valid origin country. (Latitude or longitude is missing for the origin country.)")
          return()
        }
      } else {
        print("Please select a valid origin country. (No matching origin country.)")
        return()
      }
      if (nrow(filtered_dest_entries) > 0) {
        dest_country_code <- filtered_dest_entries[1, "country_code"]
        dest_coords$latitude <- filtered_dest_entries[1, "latitude"]
        dest_coords$longitude <- filtered_dest_entries[1, "longitude"]
        if (!is.na(dest_coords$latitude) && !is.na(dest_coords$longitude)) {
          print(paste("Destination Country Code:", dest_country_code))
          print(paste("Destination Coordinates:", paste(dest_coords$latitude, dest_coords$longitude, collapse = ", ")))
          if (!is.null(map_data$map)) {
            map_data$map <- setView(map_data$map, lng = dest_coords$longitude, lat = dest_coords$latitude, zoom = 5) %>%
              addPolylines(lng = c(origin_coords$longitude, dest_coords$longitude), lat = c(origin_coords$latitude, dest_coords$latitude), color = "blue", weight = 2) %>%
              addMarkers(lng = dest_coords$longitude, lat = dest_coords$latitude, popup = input$dest_country, icon = customIcon(iconUrl = "airplane.png", iconSize = c(32, 32)))
          } else {
            map <- leaflet() %>%
              addTiles() %>%
              setView(lng = dest_coords$longitude, lat = dest_coords$latitude, zoom = 5) %>%
              addMarkers(lng = dest_coords$longitude, lat = dest_coords$latitude, popup = dest_country_code, icon = customIcon(iconUrl = "airplane.png", iconSize = c(32, 32))) %>%
              addPolylines(lng = c(origin_coords$longitude, dest_coords$longitude), lat = c(origin_coords$latitude, dest_coords$latitude), color = "blue", weight = 2)
            map_data$map <- map
          }
        }
      } else {
        print("No matching destination country.")
      }
    }
  })

  output$flight_map <- renderLeaflet({
    if (is.null(map_data$map)) {
      leaflet() %>%
        addTiles() %>%
        setView(lng = 8.5417, lat = 47.3769, zoom = 7)
    } else {
      map_data$map
    }
  })
}

shinyApp(ui = ui, server = server, options = list(host = "0.0.0.0", port = 3838))
