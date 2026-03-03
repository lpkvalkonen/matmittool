#-------------------------------------------------------------------------------
# Server file for the app
#-------------------------------------------------------------------------------

# Include Finnish in the UI
finnish_text <- list(
  search = "Haku:",
  info = "Näytetään rivit _START_–_END_ / _TOTAL_",
  infoEmpty = "Ei näytettäviä rivejä",
  infoFiltered = "(suodatettu _MAX_ rivistä)",
  lengthMenu = "Näytä _MENU_ riviä",
  zeroRecords = "Ei hakutuloksia"
)


#-------------------------------------------------------------------------------
# Define server logic
#-------------------------------------------------------------------------------
function(input, output, session) {
  # Empty prediction table
  empty_pred_table <- data.frame(
  Matkailijoita = numeric(),
  Yöpymiset = numeric(),
  Predicted = numeric(),
  Lower = numeric(),
  Upper = numeric(),
    
  # All covariates to be stored
  Päämatkakohde = character(),
  Asuinalue = character(),
  Ikäryhmä = character(),
  Majoitus = character(),
  Matkaseura = character(),
  Matkan_tarkoitus = character(),
  Sukupuoli = character(),
  Neljännes = character(),
  Kulkuväline = character(),
  Luontomatkailu = character(),
  Kulttuurimatkailu = character(),
  Kaupunkimatkailu = character(),
  Osallistui_tapahtumiin = character(),
  Ostosmatkailu = character(),
  Urheilumatkailu = character(),
  Hyvinvointimatkailu = character(),
  Kiertomatkailu = character(),
  Yli_50km_matkoja_Suomessa = character(),
  Vierailut_muissa_kohteissa = character(),
  MuutMaat = character(),
  Ensi_varaus_kk_ennen = numeric(),
  
  stringsAsFactors = FALSE
  )
  
  # Stores all predictions made
  prediction_log <- reactiveVal(empty_pred_table)
  
  # Reseting function
  reset_all <- function() {
    # Remove table selections
    DT::selectRows(DT::dataTableProxy("profiles_table"), NULL)
    # Clear predictions
    prediction_log(empty_pred_table)
  }
  
  # Reactive value for triggering prediction
  predict_trigger <- reactiveVal(0)
  
  # Reactive value for posterior_predict
  #rv <- reactiveValues(pred2 = NULL)
  
  # Initialization for single case modeling
  pred2 <- NULL
  
  # Profile data
  output$profiles_table <- DT::renderDataTable({
    profiles_data
  },
  selection = "single",
  colnames = c(
    'Päämatkakohde',
    'Asuinalue',
    'Matkan tarkoitus',
    'Ikäryhmä',
    'Matkaseura',
    'Majoitus',
    'Havaintojen lukumäärä'
  ),
  options = list(
    pageLength = nrow(profiles_data),
    paging = FALSE,
    language = finnish_text,
    scrollY = "250px",
    scrollX = TRUE
  ),)
  
  # Run reset once at app start
  observe({
    reset_all()
  })
  # Observe whether profiles are selected
  observeEvent(input$profiles_table_rows_selected, {
    # Which row is selected from the profiles table
    sel <- input$profiles_table_rows_selected
    if (length(sel) == 1) {
      pd <- profiles_data[sel, ]
      
      # Update inputs based on the selected profile (only those inputs that are used in profiling)
      updateSelectInput(session,
                        "x_mainDestination",
                        selected = as.character(pd$Päämatkakohde))
      updateSelectInput(session,
                        "x_countryOfContinent",
                        selected = as.character(pd$Asuinalue))
      updateSelectInput(session, "x_purpose", selected = as.character(pd$Matkan_tarkoitus))
      updateSelectInput(session, "x_age", selected = as.character(pd$Ikäryhmä))
      updateSelectInput(session, "x_accommodation", selected = as.character(pd$Majoitus))
      updateSelectInput(session, "x_company", selected = as.character(pd$Matkaseura))
      
    }
  })
  
  # Controlling selection of the number of tourists
  observeEvent(input$n_tourists, {
    # Convert input to numeric
    n <- suppressWarnings(as.numeric(input$n_tourists))
    
    # If input is NULL, NA (invalid), or below min, reset to 1
    if (is.null(n) || is.na(n) || n < 1) {
      updateNumericInput(session, "n_tourists", value = 1)
    }
    # If input above max, reset to max
    else if (n > 5e6) {
      updateNumericInput(session, "n_tourists", value = 5e6)
    } else{
      n_int <- round(n)
      if (n_int != n) {
        updateNumericInput(session, "n_tourists", value = n_int)
      }
    }
  }, ignoreNULL = FALSE)
  
  # Allow Predict button when n_tourist has valid value
  observe({
    # Intialize n
    n <- suppressWarnings(as.numeric(input$n_tourists))
    # Define valid value
    n_valid <- !is.null(n) && !is.na(n) && n >= 1 && n <= 5e6
    shinyjs::toggleState("runBtn", condition = n_valid)
  })
  
  # When pressing button for predictions
  observeEvent(input$runBtn, {
    # Trigger prediction
    predict_trigger(predict_trigger() + 1)
    
    #isolate({
      if (isTRUE(input$avg_pred)) {
        # Predictions
        pred_rows <- pred_data()
        
        # Selected covariates
        covs <- covariates_selected()
        
        # Convert covariates into a (single-row) data frame for logging
        base_covs_df <-
          as.data.frame(as.list(covs), stringsAsFactors = FALSE)
        
        # Current prediction log
        old_prediction_log <- prediction_log()
        
        # Build new rows (one for each LOS value if multiple selections there)
        new_rows <- lapply(seq_len(nrow(pred_rows)), function(i) {
          row <- pred_rows[i, ]
          
          df <- base_covs_df
          
          df$Yöpymiset   <- row$Yöpymiset
          df$Predicted <- round(row$Estimate)
          df$Lower     <- round(row$Lower)
          df$Upper     <- round(row$Upper)
          
          df$Matkailijoita <- input$n_tourists
          
          # Reorder columns
          df <-
            df %>% dplyr::select(Matkailijoita,
                                 Yöpymiset,
                                 Predicted,
                                 Lower,
                                 Upper,
                                 everything())
          df
        })
        
        # Show no value in the table if "-" is selected for first reservation
        if (input$x_firstReservation == "-") {
          for (i in seq_along(new_rows)) {
            new_rows[[i]]$Ensi_varaus_kk_ennen <- NA
          }
        }
        # Show no value in the table if "-" is selected for LOS
        if (input$x_LOS == "-") {
          for (i in seq_along(new_rows)) {
            new_rows[[i]]$Yöpymiset <- NA
          }
        }
        
        # Bind rows and update log
        new_rows_df <- do.call(rbind, new_rows)
        
        # Guarantee column names and order
        for (col in names(empty_pred_table)) {
          if (!col %in% names(new_rows_df)) {
            # Fill missing cols
            new_rows_df[[col]] <- NA
          }
        }
        
        # Reorder to match base table
        new_rows_df <- new_rows_df[names(empty_pred_table)]
        
        # Add into prediction log
        prediction_log(rbind(new_rows_df, old_prediction_log))
        
        
      }
      
    #})
  })
  
  # When reseting button in pressed
  observeEvent(input$resetBtn, {
    reset_all()
  })
  
  # Combine covariate selections into new data
  covariates_selected <- reactive({
    req(predict_trigger() > 0)
    predict_trigger()
    
    # Isolation block: The reactive only updates when predict_trigger() changes
    # and not solely based on changes in inputs
    isolate({
      conds <- list()
      
      lev_AsAlue   <-
        levels(data_1to15$Asuinalue)
      lev_PkSuuralue <-
        levels(data_1to15$Päämatkakohde)
      lev_Ika   <-
        levels(data_1to15$Ikäryhmä)
      lev_Majo  <-
        levels(data_1to15$Majoitus)
      lev_Seura <-
        levels(data_1to15$Matkaseura)
      lev_MatT  <-
        levels(data_1to15$Matkan_tarkoitus)
      lev_Sukup <-
        levels(data_1to15$Sukupuoli)
      lev_Nelj  <- levels(data_1to15$Neljännes)
      lev_Kulk  <- levels(data_1to15$Kulkuväline)
      lev_SegLuonto <- levels(data_1to15$Luontomatkailu)
      lev_SegKult <- levels(data_1to15$Kulttuurimatkailu)
      lev_SegKaupu  <- levels(data_1to15$Kaupunkimatkailu)
      lev_SegTapah  <- levels(data_1to15$Osallistui_tapahtumiin)
      lev_SegOstos  <- levels(data_1to15$Ostosmatkailu)
      lev_SegUrhei  <- levels(data_1to15$Urheilumatkailu)
      lev_SegHyvin  <- levels(data_1to15$Hyvinvointimatkailu)
      lev_SegKierto  <- levels(data_1to15$Kiertomatkailu)
      lev_Yli50 <- levels(data_1to15$Yli_50km_matkoja_Suomessa)
      lev_ToissijaisetKohteet  <-
        levels(data_1to15$Vierailut_muissa_kohteissa)
      lev_MuutMaat  <- levels(data_1to15$MuutMaat)
      
      # Conditions for input selections
      
      if (!is.null(input$x_mainDestination) &&
          !is.na(input$x_othercountries) &&
          input$x_mainDestination != "-") {
        conds$Päämatkakohde <-
          factor(input$x_mainDestination, levels = lev_PkSuuralue)
      }
      
      if (input$x_countryOfContinent != "-" &&
          !is.na(input$x_countryOfContinent) &&
          !is.null(input$x_countryOfContinent)) {
        conds$Asuinalue <-
          factor(input$x_countryOfContinent, levels = lev_AsAlue)
      }
      
      if (!is.null(input$x_age) &&
          !is.na(input$x_age)) {
        conds$Ikäryhmä   <- factor(input$x_age, levels = lev_Ika)
      }
      
      if (!is.null(input$x_accommodation) &&
          !is.na(input$x_accommodation)) {
        conds$Majoitus <-
          factor(input$x_accommodation, levels = lev_Majo)
      }
      
      if (!is.null(input$x_company) &&
          !is.na(input$x_company)) {
        conds$Matkaseura <-
          factor(input$x_company, levels = lev_Seura)
      }
      
      if (!is.null(input$x_purpose) &&
          !is.na(input$x_purpose)) {
        conds$Matkan_tarkoitus <-
          factor(input$x_purpose, levels = lev_MatT)
      }
      
      if (!is.null(input$x_gender) &&
          !is.na(input$x_gender)) {
        conds$Sukupuoli     <-
          factor(input$x_gender, levels = lev_Sukup)
      }
      
      if (!is.null(input$x_quarter) &&
          !is.na(input$x_quarter)) {
        conds$Neljännes  <-
          factor(input$x_quarter, levels = lev_Nelj)
      }
      
      if (!is.null(input$x_transport) &&
          !is.na(input$x_transport)) {
        conds$Kulkuväline <-
          factor(input$x_transport, levels = lev_Kulk)
      }
      
      if (!is.null(input$x_nature) &&
          !is.na(input$x_nature)) {
        conds$Luontomatkailu <-
          factor(input$x_nature, levels = lev_SegLuonto)
      }
      
      if (!is.null(input$x_culture) &&
          !is.na(input$x_culture)) {
        conds$Kulttuurimatkailu   <-
          factor(input$x_culture, levels = lev_SegKult)
      }
      
      if (!is.null(input$x_city) &&
          !is.na(input$x_city)) {
        conds$Kaupunkimatkailu  <-
          factor(input$x_city, levels = lev_SegKaupu)
      }
      
      if (!is.null(input$x_event) &&
          !is.na(input$x_event)) {
        conds$Osallistui_tapahtumiin  <-
          factor(input$x_event, levels = lev_SegTapah)
      }
      
      if (!is.null(input$x_shopping) &&
          !is.na(input$x_shopping)) {
        conds$Ostosmatkailu  <-
          factor(input$x_shopping, levels = lev_SegOstos)
      }
      
      if (!is.null(input$x_sport) &&
          !is.na(input$x_sport)) {
        conds$Urheilumatkailu  <-
          factor(input$x_sport, levels = lev_SegUrhei)
        
      }
      
      if (!is.null(input$x_wellbeing) &&
          !is.na(input$x_wellbeing)) {
        conds$Hyvinvointimatkailu  <-
          factor(input$x_wellbeing, levels = lev_SegHyvin)
        
      }
      
      if (!is.null(input$x_tour) &&
          !is.na(input$x_tour)) {
        conds$Kiertomatkailu  <-
          factor(input$x_tour, levels = lev_SegKierto)
      }
      
      
      if (!is.null(input$x_over50km) &&
          !is.na(input$x_over50km)) {
        conds$Yli_50km_matkoja_Suomessa <-
          factor(input$x_over50km, levels = lev_Yli50)
        
      }
      
      
      if (!is.null(input$x_secondary) &&
          !is.na(input$x_secondary) && input$x_secondary != "-") {
        conds$Vierailut_muissa_kohteissa <-
          factor(input$x_secondary, levels = lev_ToissijaisetKohteet)
        
      }
      
      if (!is.null(input$x_othercountries) &&
          !is.na(input$x_othercountries) &&
          input$x_othercountries != "-") {
        conds$MuutMaat <-
          factor(input$x_othercountries, levels = lev_MuutMaat)
      }
      
      if (!is.null(input$x_firstReservation) &&
          input$x_firstReservation != "-") {
        conds$Ensi_varaus_kk_ennen <- as.numeric(input$x_firstReservation)
      } else{
        conds$Ensi_varaus_kk_ennen <-
          median(data_1to15$Ensi_varaus_kk_ennen)
      }
      
      # Return the data frame
      as.data.frame(conds)
      
      # If no factor level selections are made the prediction function uses
      # the reference level
    })
  })
  
  # Conditional predictions
  preds <- reactive({
    req(predict_trigger() > 0)
    predict_trigger()
    
    # Isolation block: The reactive only updates when predict_trigger() changes
    # and not solely based on changes in inputs.
    isolate({
      fixed_covs <- covariates_selected()
      
      # Determine nights to predict
      grid <- if (input$x_LOS == "1-15") {
        1:15
      } else if (input$x_LOS == "-") {
        round(median(data_1to15$Yöpymiset))
      } else {
        as.numeric(input$x_LOS)
      }
      
      # Initialize dataframe fro predictions
      newdata <- do.call(rbind, lapply(grid, function(y) {
        row <- fixed_covs
        row$`Yöpymiset` <- y
        row
      }))
      
      # Typical scenario
      if (isTRUE(input$avg_pred)) {

        # Expected values of the posterior predictive distributions
        pred <- posterior_epred(model_1to15, newdata = newdata)
        
        # Ensure pred is a matrix
        if (is.null(dim(pred))) {
          pred <- matrix(pred, ncol = 1)
        }
        
        # Scaling based on the number of tourists
        pred <- input$n_tourists * pred
        
        # Summarize into mean and 95% credible interval
        cond_eff <- data.frame(
          Yöpymiset = grid,
          Estimate = apply(pred, 2, mean),
          Lower    = apply(pred, 2, quantile, 0.025),
          Upper    = apply(pred, 2, quantile, 0.975)
        )
        
      } else{ # Return null predictions
        pred <- NULL
        
        pred <- input$n_tourists * pred
        
        cond_eff <- data.frame(
          Yöpymiset = grid,
          Estimate = NA,
          Lower    = NA,
          Upper    = NA
        )
        
      }
      
      # Single case scenario
      if (input$n_tourists <= 1000 &
          isTRUE(input$single_pred) & input$x_LOS != "1-15") {
        newdata <- newdata[rep(1, input$n_tourists),]
        
        # Samples from posterior predictive distributions
        pred2 <- posterior_predict(model_1to15, newdata = newdata,
                                   ndraws = 1000)
        # Ensure pred is a matrix
        if (is.null(dim(pred2))) {
          pred2 <- matrix(pred2, ncol = 1)
        }
        
      } else{ # Return null predictions
        pred2 <- NULL
      }
      
      # Return predictions
      return(list(cond_eff = cond_eff, pred2 = pred2))
      
    })
  })
  
  # Histogram for one scenario
  output$histPlot <- renderPlot({
    # Check that requirements for showing the results are fulfilled
    validate(
      need(predict_trigger() > 0, message = ""),
      need(!is.null(preds()$pred2),
           message = "Ei näytettäviä arvoja! Varmista, että valintaruutu on aktiivinen, maksimissaan 1000 matkailijaa on valittuna ja matkan kesto ei ole '1-15'")
    )
    
    # Rowsums of predictions
    y <- rowSums(preds()$pred2)

    # Draw a histogram
    hist(
      y,
      col = "steelblue",
      border = "white",
      main = "",
      xlab = "Euroa",
      ylab = "Frekvenssi",
      cex.lab = 1.5,
      cex.axis = 1.5
    )
    
    # Summary statistics for individual scenario
    output$summaryText <- renderText({
      validate(need(predict_trigger() > 0, message = ""),
               need(!is.null(preds()$pred2),
                    message = ""))
      
      # Rowsums of predictions
      total_y <- rowSums(preds()$pred2)
      
      # Mean of rowsums of predictions
      mean_y <-
        mean(total_y) %>% round(0) %>% format(big.mark = " ")

      # Quantiles of rowsums of predictions
      ci_y <-
        quantile(total_y, probs = c(0.025, 0.975)) %>% round(0) %>% format(big.mark = " ")
      
      paste0(
        "Tuhannen simuloidun realisaation keskiarvo: ",
        mean_y,
        " euroa",
        " ",
        "(95% ennusteväli: ",
        ci_y[1],
        " - ",
        ci_y[2],
        " euroa)"
      )
      
    })
    
    
  })
  
  # Get predictions
  pred_data <- reactive({
    req(predict_trigger() > 0)
    x <- preds()$cond_eff
    x
  })
  
  # Prediction history table
  output$prediction_history <- DT::renderDataTable({
    
    # Check whether avg predictions are enabled
    validate(
      need(isTRUE(input$avg_pred), message = "Ei näytettäviä arvoja! Varmista, että valintaruutu on aktiivinen")
    )
    
    # Require trigger in prediction
    req(predict_trigger() > 0)
    
    # Prediction log
    df <- prediction_log()
    
    # Which column are numeric
    numeric_columns <- names(df)[sapply(df, is.numeric)]
    
    # Create data table
    DT::datatable(
      df,
      colnames = c(
        'Matkailijoita',
        'Matkan kesto (yöt)',
        'Ennustettu rahankäyttö',
        '95% luottoväli alaraja',
        '95% luottoväli yläraja',
        'Päämatkakohde',
        'Asuinalue',
        'Ikäryhmä',
        'Majoitus',
        'Matkaseura',
        'Matkan tarkoitus',
        'Sukupuoli',
        'Neljännes',
        'Kulkuväline',
        'Luontomatkailu',
        'Kulttuurimatkailu',
        'Kaupunkimatkailu',
        'Osallistui tapahtumiin',
        'Ostoksia',
        'Urheilumatkailu',
        'Hyvinvointimatkailu',
        'Kiertomatkailu',
        'Yli 50km matkoja Suomessa',
        'Vierailut muissa kohteissa',
        'Vierailu muissa maissa',
        'Ensi varaus kk ennen matkaa'
      ),
      extensions = c('Buttons'),
      options = list(
        dom = 'Bfrtip',
        scrollY = "240px",
        paging = FALSE,
        scrollCollapse = TRUE,
        buttons = list(
          list(
            extend = 'csv',
            title = "Matkailijamittari – ennustetyökalu",
            filename = 'predictions',
            text = 'CSV'
          ),
          list(
            extend = 'excel',
            title = "Matkailijamittari – ennustetyökalu",
            filename = 'predictions',
            text = 'Excel'
          ),
          list(
            extend = 'pdf',
            title = "Matkailijamittari – ennustetyökalu",
            filename = 'predictions',
            text = 'PDF',
            pageSize = "A4",
            orientation = 'landscape',
            customize = JS(
              "function(doc) {
                doc.defaultStyle.fontSize = 3;
                doc.styles.tableHeader.fontSize = 3;
                doc.pageMargins = [10, 10, 10, 10];
                doc.content[1].layout = 'lightHorizontalLines';
            }"
            )
          )
        ),
        language = finnish_text,
        scrollX = TRUE
      ),
      rownames = FALSE
    ) %>%
      formatRound(columns = numeric_columns,
                  digits = 0,
                  mark = " ")
    
  })
  
}
