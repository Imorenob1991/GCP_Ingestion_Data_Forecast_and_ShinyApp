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
