# 安装必要的包，如果尚未安装
if (!require(shiny)) install.packages("shiny")
if (!require(plotly)) install.packages("plotly")
if (!require(shinydashboard)) install.packages("shinydashboard")
if (!require("leaflet")) install.packages("leaflet")
library(shiny)
library(plotly)
library(shinydashboard)
library(leaflet)
# 创建Shiny应用程序
ui <- dashboardPage(
  dashboardHeader(title = "Flight Dashboard", titleWidth = 200),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Itinerary Overview", tabName = "overview"),
      menuItem("Result Output", tabName = "result")
    )
  ),
  dashboardBody(
    tabItems(
      # 第一部分: Itinerary Overview
      tabItem(tabName = "overview",
              fluidRow(
                box(
                  title = "Itinerary Overview",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 7,
                  textInput("start_point", "From"),
                  textInput("end_point", "To"),
                  dateInput("date", "Date"),
                  actionButton("search", "Search", style = "background-color: #be0000; color: white; border: none;")
                ),
                column(6, align = "center",  # 增加地图的列宽
                       style = "padding: 15px; border-rounded bg-lightgray map-container",
                       leafletOutput("map")
                ),
                column(5, align = "center",  # 增加饼图的列宽
                       style = "padding: 15px; border-rounded bg-lightgray chart-container",
                       plotlyOutput("market_share_pie")
                )
              )
      ),
      
      # 第二部分: Result Output
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
                  title = "Recommendations", # 表格标题
                  status = "primary",
                  solidHeader = TRUE,
                  width = 8,
                  dataTableOutput("recommendations")
                )
              ),
              fluidRow(
                box(
                  title = "Other Information", # 将 "Other Information" 移到这里
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
                  title = "Timecircuity",
                  status = "primary",
                  solidHeader = TRUE,
                  width = 4,
                  verbatimTextOutput("timecircuity")
                )
              )
      )
    )
  )
)

server <- function(input, output) {
  # Placeholder data (replace with actual data)
  dummy_data <- data.frame(
    Deptime = c("08:00", "09:00", "10:00"),
    Arrtime = c("10:00", "11:30", "12:30"),
    Elptime = c(120, 90, 60),
    Option = c("Option 1", "Option 2", "Option 3")
  )
  
  # Render the map (replace with actual map data)
  output$map <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      addMarkers(lng = 0, lat = 0, popup = "Search Result 1")
  })
  
  # Render the market share pie chart with improved style
  output$market_share_pie <- renderPlotly({
    data <- data.frame(
      Label = c("Market 1", "Market 2", "Market 3"),
      Value = c(30, 40, 30)
    )
    
    plot_ly(data, labels = ~Label, values = ~Value, type = "pie") %>%
      layout(title = "Market Share", titlefont = list(size = 18, color = "#be0000"), showlegend = TRUE) %>%
      config(displayModeBar = FALSE)  # 隐藏图表工具栏
  })
  
  # Render recommendations table (using dummy data)
  output$recommendations <- renderDataTable({
    dummy_data
  })
  
  # Render other information (replace with actual data)
  output$detour <- renderText("Detour information")
  output$stops <- renderText("Stops information")
  output$timecircuity <- renderText("Timecircuity information")
  # Render Accuracy with dummy data
  output$accuracy1 <- renderText("Accuracy 1: 90%")
  output$total_passengers <- renderText("Total passengers: 30000")
}

shinyApp(ui, server)
