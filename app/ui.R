library(shiny)
library(DT)

shinyUI(fluidPage(  
  titlePanel("RVDB - The Radial Velocities Database"),
  br(),
  tabsetPanel(id="tabs", type = "tabs", 
                tabPanel("Combined datasets", value='combined'),
                tabPanel("All datasets", value='all'),
                tabPanel("Star", value='star'),
                tabPanel("Dataset", value='dataset'),                                
              tabPanel("Help", value='help')),
  br(),
  h4("Data"),
  
  hr(),
  
  dataTableOutput('table'),
  verbatimTextOutput('text'),
  HTML("<style> .dataTables_filter { display:none } </style>")
))
