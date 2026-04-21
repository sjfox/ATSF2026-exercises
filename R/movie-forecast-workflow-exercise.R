library(fpp3)
library(here)
library(tidyverse)

here::i_am("R/movie-forecast-workflow-exercise.R")

# -----------------------------
# Step 1: Read and visualize the time series
# -----------------------------
read_csv(here('raw-data/family-movies.csv')) |> 
  mutate(month = yearmonth(month)) |> 
  as_tsibble(index = month) -> movies
  
movies |> 
  autoplot(n_releases)


## Look at the monthly counts
movies_monthly |>
  gg_season()

  
# -----------------------------
# Step 2: Create train / validation / test splits
# -----------------------------

# Training data: 1980-2013
# Validation data: 2014-2016
# Test data: 2017-2019
#
# We will only touch the test set once, at the very end.
train <- movies_monthly |>
  filter(month < yearmonth("2014 Jan"))

validation <- movies_monthly |>
  filter(month >= yearmonth("2014 Jan"), month < yearmonth("2017 Jan"))

## These are only used in final testing step
trainvalidation <- movies_monthly |> 
  filter(month < yearmonth("2017 Jan"))

test <- movies_monthly |>
  filter(month >= yearmonth("2017 Jan"))

# -----------------------------
# Step 3: Example baseline forecasting and performance on validation
# -----------------------------

baseline_fits <- train |>
  model(
    naive = NAIVE(n_releases),
    drift = RW(n_releases ~ drift()),
    snaive = SNAIVE(n_releases)
  )

## In sample fits
baseline_fits |> 
  accuracy()

## Inspect residuals
baseline_fits |> 
  select(snaive) |> 
  gg_tsresiduals()

## Test for significance
baseline_fits |> 
  select(snaive) |> 
  augment() |> 
  features(.innov, ljung_box, lag = 24)

## Now make forecasts for the validation time period and evaluate
baseline_fits |> 
  forecast(h=24) |> 
  accuracy(data = validation, 
           measures = distribution_accuracy_measures)

baseline_fits |> 
  forecast(h=24) |> 
  autoplot(data = validation)


# -----------------------------
# Step 4: Now try and get a model that is better in the validation period
# -----------------------------





# -----------------------------
# Step 5: Test your model fit against the baseline in the test period
# -----------------------------

