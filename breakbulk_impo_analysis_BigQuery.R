# Project: Break bulk Historical Analysis and Forecast Estimation
## Sector: Maritime Port.
## Objective: Import data from Google Cloud Platform into R, generate a forecast, and display the outcome in a Shiny application

library(readr)
library(lubridate)
library(tidyr)
library(dplyr)
library(ggplot2)
library(forecast)
library(plotly)
library(fpp3)
library(bigrquery)
library(shiny)
library(plotly)

library(DT)
library(tibble)

# 1. Import the Data Directly from Google Cloud Platform

## install.packages("bigrquery")

bq_auth(email = "imorenob91@gmail.com")

## Define the project in GCP
project_id <- "importchileanalysis"  # Reemplaza con tu Project ID de Google Cloud
dataset_id <- "datos_impo_chile"  # Reemplaza con el nombre del dataset
table_id <- "impo_hist_breakbulk_data"  # Reemplaza con el nombre de tu tabla

## Create the SQL query
query <- "SELECT * FROM `importchileanalysis.datos_impo_chile.impo_hist_breakbulk_data`"

## Execute the query
datos_impo_breakbulk <- bq_table_download(
  bq_project_query(project_id, query)
)

glimpse(datos_impo_breakbulk)

# 2. Preparing the data before the Time Series Modeling

## Filter and consider only the data related to Maritime Import Break bulk Operations

table(datos_impo_breakbulk$NOMBRE_VIA_TRANSPORTE)

datos_impo_breakbulk_mar = datos_impo_breakbulk %>% filter(NOMBRE_VIA_TRANSPORTE == "MARÍTIMA, FLUVIAL Y LACUSTRE")

glimpse(datos_impo_breakbulk_mar)

## Working on data types and missing values: Converting to date attributes and identifying missing values (NAs) in each column

datos_impo_breakbulk_mar$FECVENCI <- as.Date(datos_impo_breakbulk_mar$FECVENCI, format = "%Y-%m-%d")
datos_impo_breakbulk_mar$FEC_ALMAC <- as.Date(datos_impo_breakbulk_mar$FEC_ALMAC, format = "%Y-%m-%d")
datos_impo_breakbulk_mar$FECRETIRO <- as.Date(datos_impo_breakbulk_mar$FECRETIRO, format = "%Y-%m-%d")
datos_impo_breakbulk_mar$FEC_MANIF <- as.Date(datos_impo_breakbulk_mar$FEC_MANIF, format = "%Y-%m-%d")
datos_impo_breakbulk_mar$FEC_CONOC <- as.Date(datos_impo_breakbulk_mar$FEC_CONOC, format = "%Y-%m-%d")

sapply(datos_impo_breakbulk_mar, function(x) sum(is.na(x)))

## Identify all the observations without port information "NOMBRE_PUERTO_DESEM"
datos_impo_breakbulk_mar_na <- datos_impo_breakbulk_mar %>%
  filter(is.na(NOMBRE_PUERTO_DESEM))

## Generate a column in Thousand of Tons, due to the large scale numbers.
datos_impo_breakbulk_mar$TOT_PESO_M_TON = datos_impo_breakbulk_mar$TOT_PESO/1000000

## Generate the columns year and months from the operation Date.
datos_impo_breakbulk_mar$año = year(datos_impo_breakbulk_mar$FECVENCI)
datos_impo_breakbulk_mar$mes = month(datos_impo_breakbulk_mar$FECVENCI)

write.csv(datos_impo_breakbulk_mar, "impo_hist_breakbulk2.csv", row.names = FALSE, fileEncoding = "UTF-8")

# 3. General Understanding of the data and general insights

## Which countries have the highest participation in Chile's maritime break bulk imports?

data_pais_emb <- datos_impo_breakbulk_mar %>%
  group_by(año, PAIS_EMB) %>%
  summarise(ton_totales = sum(TOT_PESO_M_TON, na.rm = TRUE) %>% round(0)) %>% 
  ungroup() %>%
  group_by(año) %>%
  pivot_wider(names_from = año, values_from = ton_totales) %>%
  arrange(desc(`2024`))

data_pais_emb_porc <- data_pais_emb %>%
  mutate(across(where(is.numeric), 
                ~ round(. / sum(., na.rm = TRUE) * 100, 2))) %>%
  mutate(across(where(is.numeric), ~ replace_na(., 0))) %>% 
  mutate(dif_2024_2018 = `2024` - `2018`)

## R: The Country with more participation is Argentina with 23.85% of the total imports, and gain 7PPT from 2018 to the date.

# Analyse Trend, Seasonality and Residuals of the data

month_data <- datos_impo_breakbulk_mar %>%
  filter(año > 2018 | (año == 2018 & mes >= 2)) %>%
  group_by(año, mes) %>%
  summarise(M_TON_TOTALES = sum(TOT_PESO_M_TON, na.rm = TRUE),
            SERVICIOS_TOTALES = n()) %>%
  arrange(año, mes)

glimpse(month_data)

### Creating a Time - Series in Months , in M_TON
month_time_series_mtons <- ts(month_data[,3], start = c(2018, 2), frequency = 12)
autoplot(month_time_series_mtons)
ggseasonplot(month_time_series_mtons)

### Creating a Time - Series in Months , in services
month_time_series_services <- ts(month_data[,4], start = c(2018, 2), frequency = 12)
autoplot(month_time_series_services)
ggseasonplot(month_time_series_services)

### Analyzing the Trend - Seasonality - Reminder

decomposition <- stl(month_time_series_mtons[,1], s.window = "periodic")
autoplot(decomposition)

trend_series <- trendcycle(decomposition) # Clear seasonal or cyclicar demand (Peaks every 2 years)
autoplot(trend_series)

seasonal_series <- seasonal(decomposition)
autoplot(seasonal_series)

rem_series <- remainder(decomposition)
autoplot(rem_series)

### Finally, measure the strength of the trend and the seasonality

trend_strenght <- max(0,1-((var(rem_series)/(var(rem_series+trend_series)))))
### Trend Strength: 22% - Week (Represent that only the 22% of the variance can be attributed to the trend)

seasonal_strenght <- max(0,1-((var(rem_series)/(var(rem_series+seasonal_series)))))
### Trend Strength: 20% - Week (Represent that only the 19% of the variance can be attributed to the trend)

## 4. Applying Time Series Models and accuracy evaluation

### We train the data with observations and then we test with real data, and finally measure Errors.

month_time_series_mtons
train_data <- window(month_time_series_mtons, end = c(2024,4))

length(train_data) # 75 Months
length(month_time_series_mtons) # 79 Months Total Data

### Single Exponential Smoothing

accuracy_single <- ses(train_data, h=4) %>% accuracy(month_time_series_mtons)

autoplot(ses(train_data, h=4))

### Double Exponential - Holt Model

accuracy_holt <- holt(train_data, h=4) %>% accuracy(month_time_series_mtons)

autoplot(holt(train_data, h=4))

### Triple Exponential - Holt Winters Model

accuracy_hw <- hw(train_data, h=4, seasonal = "additive") %>% accuracy(month_time_series_mtons)

hw_model = hw(train_data, h=4, seasonal = "additive", level = 80)

hw_model$model

autoplot(hw_model)

hw_model_2024 = hw(train_data, h=8, seasonal = "additive", level = 80)

autoplot(hw_model_2024)

### ETS - Optimized

fit_ets <- ets(train_data) 

accurnacy_ets <- forecast(fit_ets, h=4) %>% accuracy(month_time_series_mtons)

autoplot(forecast(ets(train_data), h=4))

### AUTO - ARIMA - Model

arima_model <- auto.arima(train_data)

accuracy_arima <- forecast(arima_model, h=4) %>% accuracy(month_time_series_mtons)

autoplot(forecast(arima_model,h = 4)) + autolayer(fitted(arima_model))

checkresiduals(arima_model)

autoplot(forecast(arima_model,h = 4)) + autolayer(fitted(arima_model))

### SARIMA - Seasonal ARIMA

sarima_model <- auto.arima(train_data, seasonal = TRUE, 
                           D = 1,  # Seasonal differencing order (adjust as needed)
                           stepwise = FALSE,  # Use a full search for the best model
                           approximation = FALSE)  # Avoid approximation for accurate model


accuracy_sarima <- forecast(sarima_model, h=4) %>% accuracy(month_time_series_mtons)

sarima_forecast <- forecast(sarima_model, h = 4)

sarima_2024 = forecast(sarima_model, h=8) 

autoplot(sarima_forecast) + 
  autolayer(fitted(sarima_model), series="Fitted") + 
  ggtitle("SARIMA Forecast without Exogenous Factors")

checkresiduals(sarima_model)

### The best model is the SARIMA with a MAPE of 16.6% 

### Model Comparison

accuracy_single <- ses(train_data, h=4) %>% accuracy(month_time_series_mtons)
accuracy_holt <- holt(train_data, h=4) %>% accuracy(month_time_series_mtons)
accuracy_hw <- hw(train_data, h=4, seasonal = "additive") %>% accuracy(month_time_series_mtons)
accuracy_ets <- forecast(fit_ets, h=4) %>% accuracy(month_time_series_mtons)
accuracy_arima <- forecast(arima_model, h=4) %>% accuracy(month_time_series_mtons)
accuracy_sarima <- forecast(sarima_model, h=4) %>% accuracy(month_time_series_mtons)

accuracy_comparison <- rbind(
  accuracy_single[2,],
  accuracy_holt[2,],
  accuracy_hw[2,],
  accuracy_ets[2,],
  accuracy_arima[2,],
  accuracy_sarima[2,]
)

rownames(accuracy_comparison) <- c("SES", "Holt", "Holt-Winters", "ETS", "ARIMA","SARIMA")

autoplot(month_time_series_mtons) +                      # Plot the actual data
  autolayer(fitted(sarima_2024), series="Fitted", PI=FALSE, size=1) +  # Plot fitted values
  autolayer(sarima_2024, series="Forecast", PI=TRUE, alpha=0.5) +      # Forecast with 80% CI, adjust transparency
  ggtitle("Actual Data and SARIMA Forecast with Transparent Confidence Interval") +
  xlab("Year") + ylab("M_Tonnes") +
  scale_color_manual(values=c("Actual"="red", "Fitted"="green", "Forecast"="lightblue")) +
  guides(colour=guide_legend(title="Series")) +
  theme_minimal()

# 5. Creating a Shinny APP with the Forecast Results 

# Define UI for the Shiny app
ui <- fluidPage(
  titlePanel("SARIMA Forecast with Graph and Table"),
  sidebarLayout(
    sidebarPanel(
      sliderInput("forecast_horizon", 
                  "Forecast Horizon (Months):", 
                  min = 1, max = 12, value = 4)
    ),
    mainPanel(
      plotOutput("forecastPlot"),  # Output plot for the forecast
      DTOutput("forecastTable")    # Output table for forecasted data
    )
  )
)

# Define server logic for the Shiny app
server <- function(input, output) {
  
  # Reactive expression for SARIMA forecast based on the horizon input
  sarima_forecast <- reactive({
    forecast(sarima_model, h = input$forecast_horizon)
  })
  
  # Reactive expression to create the forecast table
  forecast_table <- reactive({
    forecast_data <- sarima_forecast()
    
    tibble(
      Date = format(ymd(time(forecast_data$mean)), "%Y-%m"),  # Format date as YYYY-MM
      Forecast_Mean = round(as.numeric(forecast_data$mean), 0),  # Round to 0 decimals
      Forecast_Lower_80 = round(as.numeric(forecast_data$lower[, 1]), 0),  # Round to 0 decimals
      Forecast_Upper_80 = round(as.numeric(forecast_data$upper[, 1]), 0)   # Round to 0 decimals
    )
  })
  
  # Render the forecast plot with actual, fitted, and forecasted values
  output$forecastPlot <- renderPlot({
    forecast_obj <- sarima_forecast()
    autoplot(month_time_series_mtons) +                      # Plot the actual data
      autolayer(fitted(sarima_model), series="Fitted", PI=FALSE, size=1) +  # Plot fitted values
      autolayer(forecast_obj, series="Forecast", PI=TRUE, alpha=0.5) +      # Forecast with 80% CI, adjust transparency
      ggtitle("Actual Data and SARIMA Forecast with Transparent Confidence Interval") +
      xlab("Year") + ylab("M_Tonnes") +
      scale_color_manual(values=c("Actual"="red", "Fitted"="green", "Forecast"="lightblue")) +
      guides(colour=guide_legend(title="Series")) +
      theme_minimal()
  })
  
  # Render the forecast table with forecasted mean and confidence intervals, without decimals
  output$forecastTable <- renderDT({
    datatable(forecast_table(), options = list(pageLength = 10, scrollX = TRUE))
  })
}

# Run the Shiny app
shinyApp(ui = ui, server = server)
