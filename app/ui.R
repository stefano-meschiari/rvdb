library(shiny)
library(DT)

textInput2 <- function (inputId, value = "", placeholder="") 
{
  div(class = "form-group shiny-input-container",
      tags$input(id = inputId, 
                 type = "text", class = "form-control", placeholder=placeholder, value = value))
}

stars <- readRDS('combined_star_data.rds')$name

shinyUI(fluidPage(
  fluidRow(
    column(8, h1('RVDB - The Radial Velocity Database')),
    column(4,
           br(),
           p(
             align='right',
             a(href='rvdb.tar.gz', class="btn btn-primary", 'Download database'),
             a(href='https://github.com/stefano-meschiari/rvdb', class="btn btn-success", 'Contribute on GitHub'),
             a(href='https://github.com/stefano-meschiari/rvdb/blob/master/README.md', class='btn btn-info', 'Help')             
           )
           )
  ),
  br(),
  # Stars page
  tabsetPanel(id="tabs", type = "tabs", 
              tabPanel("All stars", value='combined',
                       br(),

                       fluidRow(
                         column(12,
                                textInput2('search', '', 'Search'),
                                helpText('Example: mass > 2, teff > 4000 & teff < 5000, mass > 2 | mass < 1, telescopes %~% \'JENSCH\'')
                                )
                       ),
                       
                       hr(),
                       h2("Data"),
                       hr(),
                       
                       dataTableOutput('table'),

                       hr(),
                       h2("Plots"),
                       hr(),
                       
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
                                textInput('group_by', 'Group by:', 'ndata')
                                )

                       ),
                       plotOutput('plot', width='100%', height='600px')
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
                       tableOutput('info'),
                       hr(),
                       fluidRow(
                         column(6,
                                dataTableOutput('rvs')
                                ),
                         column(6,
                                plotOutput('plot_rvs'),
                                br(),
                                verbatimTextOutput('datasets')
                                )
                       )
                       )
              ),  
  HTML("<style> .dataTables_filter { display:none } input[type=search] { font-size: 70% } </style>"),
  HTML("<script src='js/app.js'></script>")
))
