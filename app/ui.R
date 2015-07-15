library(shiny)
library(DT)
library(stringr)

textInput2 <- function (inputId, value = "", placeholder="") 
{
  div(class = "form-group shiny-input-container",
      tags$input(id = inputId, 
                 type = "text", class = "form-control", placeholder=placeholder, value = value))
}

stars <- readRDS('combined_star_data.rds')$name
stars <- stars[order(str_to_upper(stars))]

shinyUI(fluidPage(
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "http://fonts.googleapis.com/css?family=Source+Sans+Pro:200,300,400,700,200italic,300italic,700italic"),
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")
  ),
  fluidRow(    
    id="title-container",
    
    #HTML('<button id="menu" class="toolbar-btn"><i class="fa fa-bars"></i></button>'),
    a(href='https://github.com/stefano-meschiari/rvdb/raw/master/app/rvdb.tar.gz', class="toolbar-btn", icon('download'), ' Download database', target='_blank'),
    a(href='https://github.com/stefano-meschiari/rvdb', class="toolbar-btn", icon('github'), ' Contribute on GitHub', target='_blank'),
    a(href='https://github.com/stefano-meschiari/rvdb/blob/master/README.md', class='toolbar-btn', icon('question'), ' Help', target='_blank'),

    div(class='title', 'RVDB')    
  ),
  # Stars page
  tabsetPanel(id="tabs", type = "tabs", 
              tabPanel("All stars", value='combined',
                       br(),

                       fluidRow(
                         column(3,
                                textInput2('search', '', 'Search')
                                ),
                         column(9,
                                helpText('Example: HD 170693, mass > 2, teff > 4000 & teff < 5000, mass > 2 | mass < 1, telescopes %~% \'JENSCH\'')
                                )
                       ),

                       h2("Data"),
                       div(class="well",                       
                           dataTableOutput('table')
                           ),
                       br(),
                       h2("Plots"),
                       div(class="well",
                           fluidRow(
                             column(6,
                                    selectInput('plot_type', 'Type:', choices=list('Histogram', 'Scatter plot'), selected=1)
                                    ),
                             column(2, 
                                    textInput('x_axis', 'X axis:', 'mass')
                                    ),
                             column(2, 
                                    textInput('y_axis', 'Y:', 'teff')
                                    ),
                             column(2,
                                    textInput('group_by', 'Group by:', NULL)
                                    )

                           ),
                           plotOutput('plot', width='100%', height='600px')
                           )
                       ),


              # Star view
              tabPanel("Star", value='star',
                       br(),
                       fluidRow(
                         column(4,
                                selectInput('star', NULL, stars, selectize=FALSE)
                                ),
                         column(8,
                                p(align='right',
                                  actionButton('nexsci', 'Find on Exoplanet Archive', onclick='nexsci()'),  
                                  actionButton('simbad', 'Find on SIMBAD', onclick='simbad()'),
                                  actionButton('exoplanetsorg', 'Find on Exoplanets.org', onclick='exoplanetsorg()')
                                  )
                                )
                       ),
                       h2("Properties"),
                       tableOutput('info'),
                       fluidRow(
                         column(6,
                                h2("Data"),
                                div(class="well",
                                    dataTableOutput('rvs')
                                    )
                                ),
                         column(6,
                                h2("Radial velocities"),
                                div(class="well",
                                    plotOutput('plot_rvs', width='100%')
                                    ),
                                h2("Periodogram"),
                                div(class="well",
                                    imageOutput('plot_periodogram', width="100%", height=NULL),
                                    br(),
                                    tableOutput('periodogram')
                                    ),
                                h2("Datasets"),
                                verbatimTextOutput('datasets')
                                )
                       )
                       )
              ),  
  HTML("<script src='js/app.js'></script>")
))
