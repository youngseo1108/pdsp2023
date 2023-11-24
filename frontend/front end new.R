# Install necessary packages if not already installed
if (!require("shiny")) install.packages("shiny")
if (!require("shinyjs")) install.packages("shinyjs")
if (!require("dplyr")) install.packages("dplyr")
if (!require("shinydashboard")) install.packages("shinydashboard")
if (!require("leaflet")) install.packages("leaflet")
if (!require("plotly")) install.packages("plotly")

# Load the required libraries
library(shiny)
library(shinyjs)
library(dplyr)
library(shinydashboard)
library(leaflet)
library(plotly)

# Define customIcon function
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

# Define a vector of weekdays
weekdays_vector <- c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")

# Create a Shiny app
ui <- dashboardPage(
  dashboardHeader(
    title = "Flight Dashboard",
    titleWidth = 200,
    # Apply theme color to the header
    tags$li(class = "dropdown",
            tags$style(HTML(".main-header { background-color: #8B0000; }"))
    )
  ),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Itinerary Overview", tabName = "overview")
    ),
    # Change sidebar color here
    tags$style(
      HTML(".main-sidebar { background-color: #8B0000; }")
    ),
    collapsed = TRUE  # Initially collapsed
  ),
  dashboardBody(
    # Apply theme color to the body
    tags$style(HTML("body, .main-sidebar, .right-side, .wrapper { background-color: #8B0000; }")),
    tabItems(
      # Part 1: Itinerary Overview
      tabItem(tabName = "overview",
              fluidRow(
                box(
                  title = "Itinerary Overview",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 6,
                  selectInput("departure_day", "Departure Day:", choices = weekdays_vector),
                  selectInput("origin_country", "Origin Country", choices = country_codes),
                  selectInput("dest_country", "Destination Country", choices = country_codes),
                  actionButton("plot_route", "Search", style = "color: #fff; background-color: #FF0000;")
                ),
                # Make the map longer
                column(6, align = "center",
                       style = "padding: 13px; border-rounded bg-lightgray map-container",
                       leafletOutput("flight_map")
                )
              ),
              fluidRow(
                # Make the pie chart and Total Passengers/Accuracy each take up half of the row
                column(6, align = "center",
                       style = "padding: 15px; border-rounded bg-lightgray chart-container",
                       plotlyOutput("market_share_pie")
                ),
                column(6,
                       box(
                         title = "Total Passengers",
                         status = "primary",
                         solidHeader = TRUE,
                         width = 10,
                         verbatimTextOutput("total_passengers"),
                         style = "margin-top: 40px; margin-bottom: 20px;"  # Adjust margin-top and margin-bottom
                       ),
                       box(
                         title = "Accuracy",
                         status = "primary",
                         solidHeader = TRUE,
                         width = 10,
                         verbatimTextOutput("accuracy1"),
                         style = "margin-top: 40px; margin-bottom: 20px;"  # Adjust margin-top and margin-bottom
                       )
                ),
                # Add some spacing between the boxes
                style = "margin-bottom: 20px;"
              ),
              fluidRow(
                # Make the "Recommendations" box longer
                box(
                  title = "Recommendations",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 12,  # Adjusted to take up the full width
                  dataTableOutput("recommendations"),
                  style = "margin-top: 15px;"  # Adjusted margin-top for spacing
                )
              ),
              fluidRow(
                box(
                  title = "Other Information",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 3
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
  map_data <- reactiveValues(map = NULL)  # Initialize map_data outside of observe
  
  observeEvent(input$plot_route, {
    # Filter origin airport names based on user input
    filtered_origin_entries <- world_data %>%
      filter(grepl(tolower(input$origin_country), tolower(country_code)))
    
    # Check if there are any matching entries
    if (nrow(filtered_origin_entries) > 0) {
      # Access the country_code, latitude, and longitude of the first row
      origin_country_code <- filtered_origin_entries[1, "country_code"]
      origin_latitude <- filtered_origin_entries[1, "latitude"]
      origin_longitude <- filtered_origin_entries[1, "longitude"]
      print(paste("Origin Country Code:", origin_country_code))
      print(paste("Origin Coordinates:", paste(origin_latitude, origin_longitude, collapse = ", ")))
      
      if (!any(is.na(origin_latitude), is.na(origin_longitude))) {
        # Create a map centered at the selected country
        map <- leaflet() %>%
          addTiles() %>%
          setView(lng = origin_longitude, lat = origin_latitude, zoom = 5)
        
        # Add a marker for the selected country with a custom icon
        map <- map %>%
          addMarkers(lng = origin_longitude, lat = origin_latitude, popup = origin_country_code)
        
        # Store the map data in the reactiveValues object
        map_data$map <- map
      }
    } else {
      print("No matching origin country.")
    }
    
    # Filter destination entries based on user input
    filtered_dest_entries <- world_data %>%
      filter(grepl(tolower(input$dest_country), tolower(country_code)))
    
    # Check if there are any matching entries
    if (nrow(filtered_dest_entries) > 0) {
      # Access the country_code, latitude, and longitude of the first row
      dest_country_code <- filtered_dest_entries[1, "country_code"]
      dest_latitude <- filtered_dest_entries[1, "latitude"]
      dest_longitude <- filtered_dest_entries[1, "longitude"]
      print(paste("Destination Country Code:", dest_country_code))
      print(paste("Destination Coordinates:", paste(dest_latitude, dest_longitude, collapse = ", ")))
      
      if (!any(is.na(dest_latitude), is.na(dest_longitude))) {
        # If map is already initialized, update the view
        if (!is.null(map_data$map)) {
          map_data$map <- setView(map_data$map, lng = dest_longitude, lat = dest_latitude, zoom = 5)
          
          # Add a polyline to connect origin and destination
          map_data$map <- addPolylines(map_data$map, lng = c(origin_longitude, dest_longitude), lat = c(origin_latitude, dest_latitude), color = "blue", weight = 2)
          
          # Add a marker for the destination country with a custom icon
          map_data$map <- addMarkers(map_data$map, lng = dest_longitude, lat = dest_latitude, popup = dest_country_code, icon = customIcon(iconUrl = "airplane.png", iconSize = c(32, 32)))
        } else {
          # If map is not initialized, create a new map centered at the selected country
          map <- leaflet() %>%
            addTiles() %>%
            setView(lng = dest_longitude, lat = dest_latitude, zoom = 5)
          
          # Add a marker for the selected country with a custom icon
          map <- map %>%
            addMarkers(lng = dest_longitude, lat = dest_latitude, popup = dest_country_code, icon = customIcon(iconUrl = "airplane.png", iconSize = c(32, 32)))
          
          # Add a polyline to connect origin and destination
          map <- addPolylines(map, lng = c(origin_longitude, dest_longitude), lat = c(origin_latitude, dest_latitude), color = "blue", weight = 2)
          
          # Store the map data in the reactiveValues object
          map_data$map <- map
        }
      }
    } else {
      print("No matching destination country.")
    }
  })
  
  # Render the map
  output$flight_map <- renderLeaflet({
    if (is.null(map_data$map)) {
      # Set the initial view to the center of the world
      leaflet() %>%
        addTiles() %>%
        setView(lng = 0, lat = 30, zoom = 2)
    } else {
      map_data$map
    }
  })
  
  # Placeholder data (replace with actual data)
  dummy_data <- data.frame(
    Depthours = c("08:00", "09:00", "10:00"),
    Arrhours = c("10:00", "11:30", "12:30"),
    Elptime = c(120, 90, 60),
    Option = c("Create", "Cancel","Cancel")
  )
  
  # Render the market share pie chart with improved style
  output$market_share_pie <- renderPlotly({
    data <- data.frame(
      Label = c("Market 1", "Market 2", "Market 3"),
      Value = c(30, 40, 30)
    )
    
    plot_ly(data, labels = ~Label, values = ~Value, type = "pie") %>%
      layout(
        title = "Market Share",
        titlefont = list(size = 18, color = "#be0000"),
        showlegend = FALSE,
        margin = list(l = 20, r = 20, b = 20, t = 60),  # Adjust the margins for better appearance
        paper_bgcolor = "#F8F9FA",  # Set background color
        plot_bgcolor = "#F8F9FA"   # Set plot area color
      ) %>%
      config(displayModeBar = FALSE)  # Hide the chart toolbar
  })
  
  # Render recommendations table (using dummy data)
  output$recommendations <- renderDataTable({
    dummy_data
  })
  
  # Render other information (replace with actual data)
  output$detour <- renderText("Detour information")
  output$stops <- renderText("Stops information")
  output$Distance <- renderText("Distance information")
  # Render Accuracy with dummy data
  output$accuracy1 <- renderText("Accuracy 1: 90%")
  output$total_passengers <- renderText("Total passengers: 30000")
}

# Run the Shiny app
shinyApp(ui, server)
