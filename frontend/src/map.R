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

# Read the airport-codes.csv file
airport_data <- read.csv("airport-codes.csv")

# Extract unique country codes from the data
iso_countries <- sort(unique(airport_data$iso_country))

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
      menuItem("Itinerary Overview", tabName = "overview"),
      menuItem("Result Output", tabName = "result")
    ),
    # Change sidebar color here
    tags$style(
      HTML(".main-sidebar { background-color: #8B0000; }")
    )
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
                  width = 4,
                  dateInput("departure_date", "Select Departure Date:", value = Sys.Date()),
                  selectInput("origin_country", "Select Origin Country", choices = iso_countries),
                  selectInput("origin_airport", "Select Origin Airport", choices = NULL),
                  selectInput("dest_country", "Select Destination Country", choices = iso_countries),
                  selectInput("dest_airport", "Select Destination Airport", choices = NULL),
                  actionButton("plot_route", "Search"),
                ),
                column(6, align = "center",  # Increase column width for the map
                       style = "padding: 15px; border-rounded bg-lightgray map-container",
                       leafletOutput("flight_map")
                ),
                column(6, align = "center",  # Increase column width for the pie chart
                       style = "padding: 15px; border-rounded bg-lightgray chart-container",
                       plotlyOutput("market_share_pie")
                )
              )
      ),
      
      
      # Part 2: Result Output
      tabItem(tabName = "result",
              fluidRow(
                box(
                  title = "Total Passengers",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 4,
                  verbatimTextOutput("total_passengers")
                ),
                box(
                  title = "Accuracy",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 4,
                  verbatimTextOutput("accuracy1")
                )
              ),
              fluidRow(
                box(
                  title = "Recommendations", # Table title
                  status = "primary",
                  solidHeader = TRUE,
                  width = 8,
                  dataTableOutput("recommendations")
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
  
  # Update airport choices based on the selected country
  observeEvent(input$origin_country, {
    # Filter airport data based on the selected origin country
    airports_for_origin <- airport_data %>%
      filter(iso_country == input$origin_country)
    
    # Update choices for origin airport dropdown
    updateSelectInput(session, "origin_airport", choices = airports_for_origin$iata_code)
  })
  
  observeEvent(input$dest_country, {
    # Filter airport data based on the selected destination country
    airports_for_dest <- airport_data %>%
      filter(iso_country == input$dest_country)
    
    # Update choices for destination airport dropdown
    updateSelectInput(session, "dest_airport", choices = airports_for_dest$iata_code)
  })
  
  observeEvent(input$plot_route, {
    # Filter origin airport names based on user input
    filtered_origin_airports <- airport_data %>%
      filter(grepl(tolower(input$origin_airport), tolower(iata_code)))
    
    # Check if there are any matching airports
    if (nrow(filtered_origin_airports) > 0) {
      # Access the iata_code and coordinates of the first row
      origin_iata_code <- filtered_origin_airports[1, "iata_code"]
      origin_coords <- as.numeric(strsplit(filtered_origin_airports[1, "coordinates"], ", ")[[1]])
      print(paste("Origin Airport IATA Code:", origin_iata_code))
      print(paste("Origin Airport Coordinates:", paste(origin_coords, collapse = ", ")))
      
      if (!any(is.na(origin_coords))) {
        # Create a map centered at the selected airport
        map <- leaflet() %>%
          addTiles() %>%
          setView(lng = origin_coords[1], lat = origin_coords[2], zoom = 4)
        
        # Add a marker for the selected airport with a custom icon
        map <- map %>%
          addMarkers(lng = origin_coords[1], lat = origin_coords[2], popup = origin_iata_code)
        
        # Store the map data in the reactiveValues object
        map_data$map <- map
      }
    } else {
      print("No matching origin airport.")
    }
    
    # Filter destination airport names based on user input
    filtered_dest_airports <- airport_data %>%
      filter(grepl(tolower(input$dest_airport), tolower(iata_code)))
    
    # Check if there are any matching airports
    if (nrow(filtered_dest_airports) > 0) {
      # Access the iata_code and coordinates of the first row
      dest_iata_code <- filtered_dest_airports[1, "iata_code"]
      dest_coords <- as.numeric(strsplit(filtered_dest_airports[1, "coordinates"], ", ")[[1]])
      print(paste("Destination Airport IATA Code:", dest_iata_code))
      print(paste("Destination Airport Coordinates:", paste(dest_coords, collapse = ", ")))
      
      if (!any(is.na(dest_coords))) {
        # If map is already initialized, update the view
        if (!is.null(map_data$map)) {
          map_data$map <- setView(map_data$map, lng = dest_coords[1], lat = dest_coords[2], zoom = 4)
          
          # Add a polyline to connect origin and destination
          map_data$map <- addPolylines(map_data$map, lng = c(origin_coords[1], dest_coords[1]), lat = c(origin_coords[2], dest_coords[2]), color = "blue", weight = 2)
          
          # Add a marker for the destination airport with a custom icon
          map_data$map <- addMarkers(map_data$map, lng = dest_coords[1], lat = dest_coords[2], popup = dest_iata_code, icon = customIcon(iconUrl = "airplane.png", iconSize = c(32, 32)))
        } else {
          # If map is not initialized, create a new map centered at the selected airport
          map <- leaflet() %>%
            addTiles() %>%
            setView(lng = dest_coords[1], lat = dest_coords[2], zoom = 4)
          
          # Add a marker for the selected airport with a custom icon
          map <- map %>%
            addMarkers(lng = dest_coords[1], lat = dest_coords[2], popup = dest_iata_code, icon = customIcon(iconUrl = "airplane.png", iconSize = c(32, 32)))
          
          # Add a polyline to connect origin and destination
          map <- addPolylines(map, lng = c(origin_coords[1], dest_coords[1]), lat = c(origin_coords[2], dest_coords[2]), color = "blue", weight = 2)
          
          # Store the map data in the reactiveValues object
          map_data$map <- map
        }
      }
    } else {
      print("No matching destination airport.")
    }
  })
  
  # Render the map
  output$flight_map <- renderLeaflet({
    if (is.null(map_data$map)) {
      # Set the initial view to Zurich (latitude: 47.3769, longitude: 8.5417)
      leaflet() %>%
        addTiles() %>%
        setView(lng = 8.5417, lat = 47.3769, zoom = 7)
    } else {
      map_data$map
    }
  })
  
  # Placeholder data (replace with actual data)
  dummy_data <- data.frame(
    Deptime = c("08:00", "09:00", "10:00"),
    Arrtime = c("10:00", "11:30", "12:30"),
    Elptime = c(120, 90, 60),
    Option = c("Option 1", "Option 2", "Option 3")
  )
  
  # Render the market share pie chart with improved style
  output$market_share_pie <- renderPlotly({
    data <- data.frame(
      Label = c("Market 1", "Market 2", "Market 3"),
      Value = c(30, 40, 30)
    )
    
    plot_ly(data, labels = ~Label, values = ~Value, type = "pie") %>%
      layout(title = "Market Share", titlefont = list(size = 18, color = "#be0000"), showlegend = TRUE) %>%
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
