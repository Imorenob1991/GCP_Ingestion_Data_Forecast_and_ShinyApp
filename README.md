# GCP_Ingest_Data_Forecast_and_ShinyApp
This repository contains a project for ingesting data from Google Cloud Platform (GCP) into R, performing multiple time series models, and evaluating and visualizing the results. Finally, the best model (SARIMA) is developed in an interactive Shiny App.

# 1. Import the Data Directly from Google Cloud Platform (The data must be already uploaded into BigQuery in Google Cloud Platform)
- Install the necessary package: install.packages("bigrquery")
- Define the project and dataset in GCP (Google Cloud Platform)
- Create the SQL query to retrieve the data
- Execute the query and load the database directly from GCP into R Studio.

# 2. Preparing the data before the Time Series Modeling
- Filter and consider only the data related to Maritime Import Break bulk Operations.
- Working on data types and missing values: Converting to date attributes and identifying missing values (NAs) in each column.
- Generate a column in Thousand of Tons, due to the large scale numbers.
- Generate the columns year and months from the operation Date.

# 3. General Understanding of the data and general insights

- Which countries have the highest participation in Chile's maritime break bulk imports?
- R: The country with the highest participation is Argentina, accounting for 23.85% of total imports, and gaining 7 percentage points (PPT) from 2018 to the present

    <img width="729" alt="Screenshot 2024-10-15 at 23 55 26" src="https://github.com/user-attachments/assets/a2bab8d9-77c1-4c3e-a11b-347fc5c34fc4">

# 4. Applying Time Series Models and accuracy evaluation

- We train the data with observations and then we test with real data, and finally measure Errors. (75 Months of training and 4 of Testing)
- We applied the following models:
1. Single Exponential Smoothing (SES): A basic time series model that smooths the data by applying exponentially decreasing weights.
2. Holt’s Linear Trend Model: A method that extends SES by including a linear trend component to account for changes in level and trend over time.
3. Holt-Winters Model: An extension of Holt’s model that adds seasonality to the forecast, allowing it to model both trend and seasonal components.
4. ETS (Error, Trend, Seasonality): A comprehensive exponential smoothing method that automatically selects the best configuration of error, trend, and seasonality components.
5. ARIMA (AutoRegressive Integrated Moving Average): A widely used forecasting method that captures autocorrelations in the data, providing robust results for stationary series.
6. SARIMA (Seasonal ARIMA): An extension of ARIMA that incorporates seasonal differencing to account for periodic fluctuations in the data.
   
- The results of the models are the following:

     <img width="651" alt="Screenshot 2024-10-15 at 23 59 07" src="https://github.com/user-attachments/assets/e185ac93-39e3-4b6c-b40e-87a4bff963bc">

R: Despite ARIMA being the best-performing model, we identified a clear seasonality in the data. Therefore, we will use the SARIMA model as the best-fitting model.

# 5. Shinny App with an Interactive Forecast and a Table that shows the Results of the SARIMA Forecast

<img width="1428" alt="Screenshot 2024-10-16 at 00 06 05" src="https://github.com/user-attachments/assets/3dfd5ea2-1273-4b18-b80a-a9b01486d218">



