#---------------------------------------------------------
# UI for the app
#---------------------------------------------------------

#---------------------------------------------------------
# Define UI
#---------------------------------------------------------
fluidPage(
  
  # CSS-styles
  tags$head(
    tags$style(HTML("
    body {
      font-size: 24px;
      font-family: Arial, sans-serif;
    }
    h1, h2, h3, h4, h5, h6 {
      font-weight: bold;
    }
    .well {
      font-size: 22px;
    }
    .shiny-input-container {
      font-size: 22px;
    }
    .dataTables_wrapper {
      font-size: 22px;
    }
    input[type='checkbox'] { 
      transform: scale(1.5); 
      margin-right:10px; 
    }
  "))
  ),
  
  # Header of the app
  titlePanel("Matkailijamittari - ennustetyökalu "),
  
  column(
    width = 10,
    offset = 1,
    navset_card_underline(
      # Tool panel
      nav_panel("Kulutus",
                
                sidebarLayout(
                  sidebarPanel(
                    
                    h3('Profiili',
                       style = "font-weight: bold;"),
                    
                    # Input selections
                    fluidRow(
                      column(
                        width = 6,
                        
                        numericInput(
                          inputId = "n_tourists",
                          label = "Matkailijoita",
                          value = 1,
                          min = 1,
                          max = 5e6,
                          step = 1
                        ),
                        
                        selectInput(
                          "x_LOS",
                          "Matkan kesto (yöt)",
                          choices = c("-" = "-", 1:15, "1-15"),
                          selected = "-"
                        ),
                        
                        wellPanel(
                          style = "background-color: #e6f2ff; border: 1px solid #ccc; padding: 10px;",
                          
                          selectInput(
                            'x_mainDestination',
                            'Päämatkakohde',
                            choices = c("-" = NA,
                                        levels(data_1to15$Päämatkakohde)
                            ),
                            selected = NA
                          ),
                          
                          # Country of residence
                          selectInput(
                            'x_countryOfContinent',
                            'Asuinalue',
                            choices = c("-" = NA, sort(as.character(
                              unique(data_1to15$Asuinalue)
                            ))),
                            selected = NA
                          ),
                          
                          selectInput(
                            'x_purpose',
                            'Matkan tarkoitus',
                            choices = c(
                              "-" = NA, levels(data_1to15$Matkan_tarkoitus)
                              
                            )
                          ),
                          
                          selectInput(
                            'x_age',
                            'Ikäryhmä',
                            choices = c(
                              "-" = NA, levels(data_1to15$Ikäryhmä)
                            )
                          ),
                          
                          selectInput(
                            'x_company',
                            'Matkaseura',
                            choices = c(
                              "-" = NA, levels(data_1to15$Matkaseura)
                            )
                          ),
                          
                          selectInput(
                            'x_accommodation',
                            'Majoitus',
                            choices = c(
                              "-" = NA, levels(data_1to15$Majoitus)
                            )
                          )
                        ),
                        
                        selectInput(
                          'x_gender',
                          'Sukupuoli',
                          choices = c(
                            "-" = NA,
                            levels(data_1to15$Sukupuoli)
                          )
                        ),
                        
                        selectInput(
                          'x_transport',
                          'Kulkuväline',
                          choices = c(
                            "-" = NA, levels(data_1to15$Kulkuväline)
                          )
                        ),
                        
                        selectInput(
                          'x_quarter',
                          'Neljännes',
                          choices = c(
                            "-" = NA,
                            levels(data_1to15$Neljännes)
                          )
                        ),
                        
                        pickerInput(
                          inputId = "x_firstReservation",
                          label = "Ensivaraus kk ennen matkaa",
                          choices = c("-" = "-", 0:max(data_1to15$Ensi_varaus_kk_ennen)),
                          selected = "-",
                          options = list(dropupAuto = TRUE)
                        )
                        
                        
                      ),
                      
                      column(
                        width = 6,
                        selectInput('x_nature', 'Luontomatkailu', choices = c(
                          "-" = NA, levels(data_1to15$Luontomatkailu)
                        )),
                        selectInput('x_culture', 'Kulttuurimatkailu', choices = c(
                          "-" = NA, levels(data_1to15$Kulttuurimatkailu)
                        )),
                        selectInput('x_city', 'Kaupunkimatkailu', choices = c(
                          "-" = NA, levels(data_1to15$Kaupunkimatkailu)
                        )),
                        selectInput('x_event', 'Tapahtumaan osallistuminen', choices = c(
                          "-" = NA, levels(data_1to15$Osallistui_tapahtumiin)
                        )),
                        selectInput('x_shopping', 'Ostosmatkailu', choices = c(
                          "-" = NA, levels(data_1to15$Ostosmatkailu)
                        )),
                        selectInput('x_sport', 'Urheilumatkailu', choices = c(
                          "-" = NA, levels(data_1to15$Urheilumatkailu)
                        )),
                        selectInput('x_wellbeing', 'Hyvinvointimatkailu', choices = c(
                          "-" = NA, levels(data_1to15$Hyvinvointimatkailu)
                        )),
                        selectInput('x_tour', 'Kiertomatkailu', choices = c(
                          "-" = NA, levels(data_1to15$Kiertomatkailu)
                        )),
                        selectInput(
                          'x_over50km',
                          'Yli 50km matkoja Suomessa',
                          choices = c(
                            "-" = NA, levels(data_1to15$Yli_50km_matkoja_Suomessa)
                          )
                        ),
                        selectInput('x_secondary', 'Vierailut muissa kohteissa', choices = c(
                          "-" = NA, levels(data_1to15$Vierailut_muissa_kohteissa)
                        )),
                        selectInput('x_othercountries', 'Vierailu muissa maissa', choices = c(
                          "-" = NA, levels(data_1to15$MuutMaat)
                        ))
                        
                      )
                    )),
                  
                  # Main panel
                  mainPanel(
                    div(style = "padding: 30px; background-color: #f9f9f9;",
                        
                        tags$div(
                          style = "
                                display: flex;
                              ",
                          
                          # Buttons and tick boxes
                          fluidRow(
                            column(
                              width = 6,
                              actionButton("runBtn",
                                           "Laske rahankäyttö",
                                           class = "btn btn-primary btn-block",
                                           style = "font-size: 20px; height: 50px; padding: 10px 15px;")
                            ),
                            
                            column(
                              width = 6,
                              actionButton(
                                "resetBtn",
                                "Nollaa ennusteet",
                                icon = icon("redo"),
                                class = "btn btn-secondary btn-block",
                                style = "font-size: 20px; height: 50px; padding: 10px 15px;"
                              )
                            ),
                            
                            column(
                              width = 6,
                              checkboxInput(
                                label = "Keskimääräinen skenaario",
                                inputId = "avg_pred",
                                value = TRUE
                              ),
                              checkboxInput(
                                label = "Yksittäinen skenaario",
                                inputId = "single_pred",
                                value = TRUE
                              )
                            )
                            
                          )
                        )),
                    
                    # Profiles from data (table)
                    fluidRow(column(
                      width = 12,
                      div(
                        h3("Valitse datassa havaituista profiileista",
                           style = "font-weight: bold;"),
                        width = 10,
                        DT::DTOutput("profiles_table", height = 30)
                      ),
                    )),
                    
                    fluidRow(column(
                      width = 12,
                      tags$hr(style = "
                              border: none;
                              border-top: 10px solid #e6f2ff;
                              margin: 30px 0;
                            ")
                    )),
                    
                    # Prediction table for typical and single scenario
                    fluidRow(column(
                      width = 12,
                      
                      tabsetPanel(
                        tabPanel("Keskimääräinen skenaario",
                                   shinycssloaders::withSpinner(
                                     DT::dataTableOutput("prediction_history"),
                                     type = 4,
                                     color = "#007BFF"
                                   )
                        ),
                        tabPanel(
                          "Yksittäinen skenaario",
                          plotOutput("histPlot", width = "800px", height = "450px"),  # top
                          div(
                            textOutput("summaryText"), 
                            style = "font-size: 20px;"
                          )
                        )


                      )

                    ))
                  )
                  
                )
      ),
      
      #-------------------------------------------------------------------------
      # FAQ page
      #-------------------------------------------------------------------------
      
      nav_panel(
        "Ohjeet",
        mainPanel(
          #style = "height: 1200px; overflow-y: auto; padding-right: 15px;",
          tags$style(HTML("
            
            body {
              font-size: 30px;
            }
          
            #manual_container p {
              margin-top: 40px !important;
              margin-bottom: 40px !important;
            }
          ")),
          includeHTML("manual_and_faq.html")
        )
      )
      
    )
  )
)