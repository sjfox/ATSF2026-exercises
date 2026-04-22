library(fpp3)
library(here)
library(tidyverse)

here::i_am("R/movie-forecast-workflow-exercise-solution.R")

# -----------------------------
# Step 1: Read and visualize the time series
# -----------------------------
read_csv(here('raw-data/family-movies.csv'), show_col_types = FALSE) |> 
  mutate(month = yearmonth(month)) |> 
  as_tsibble(index = month) -> movies_monthly

movies_monthly |> 
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
  features(.innov, ljung_box, lag = 36)

## Now make forecasts for the validation time period and evaluate
baseline_fits |> 
  forecast(h = 36) |> 
  accuracy(data = validation, 
           measures = distribution_accuracy_measures)

baseline_fits |> 
  forecast(h = 36) |> 
  autoplot(data = validation)


# -----------------------------
# Step 4: Now try and get a model that is better in the validation period
# -----------------------------

## The seasonal naive model did well, so the next question is:
## can ARIMA capture the remaining autocorrelation and improve out-of-sample 
## validation performance?


train |> 
  gg_tsdisplay(n_releases,plot_type='partial')

train |> 
  gg_tsdisplay(difference(n_releases, 12) |> 
                 difference(), plot_type='partial')


arima_fits <- train |>
  model(
    arima_auto = ARIMA(n_releases, stepwise = F, approx=FALSE)
  )

## Check residuals of the best fit model
arima_fits |> 
  gg_tsresiduals()

arima_fits |> 
  augment() |>
  features(.innov, ljung_box, lag = 36, dof = 6)

## Get Validation performance
arima_fits |>
  forecast(h = 36) |>
  accuracy(
    data = validation,
    measures = distribution_accuracy_measures) 

arima_fits |>
  forecast(h= 36) |> 
  autoplot(data=trainvalidation)


arima_reduced <- train |>
  model(
    arima_111112 = ARIMA(n_releases ~ pdq(1,1,1) + PDQ(1,1,2)),
    arima_110112 = ARIMA(n_releases ~ pdq(1,1,0) + PDQ(1,1,2)),
    arima_010112 = ARIMA(n_releases ~ pdq(0,1,0) + PDQ(1,1,2)),
    arima_010112 = ARIMA(n_releases ~ pdq(0,1,0) + PDQ(1,1,2)),
    arima_112112 = ARIMA(n_releases ~ pdq(1,1,2) + PDQ(1,1,2)),
    arima_112111 = ARIMA(n_releases ~ pdq(1,1,2) + PDQ(1,1,1)),
    arima_112110 = ARIMA(n_releases ~ pdq(1,1,2) + PDQ(1,1,0)),
    arima_111011 = ARIMA(n_releases ~ pdq(1,1,1) + PDQ(0,1,1)),
    arima_111010 = ARIMA(n_releases ~ pdq(1,1,1) + PDQ(0,1,0)),
    arima_110110 = ARIMA(n_releases ~ pdq(1,1,0) + PDQ(1,1,0)),
    arima_110010 = ARIMA(n_releases ~ pdq(1,1,0) + PDQ(0,1,0))
  )
  
arima_reduced |>
  forecast(h = 36) |>
  accuracy(
    data = validation,
    measures = distribution_accuracy_measures) 


arima_fits |> report()


# -----------------------------
# Step 5: Test your model fit against the baseline in the test period
# -----------------------------

## Now that the model choice has been made using the validation set, refit the
## selected ARIMA model on all non-test data, then compare it with seasonal naive
## on the untouched test period.

final_snaive_fit <- trainvalidation |>
  model(snaive = SNAIVE(n_releases))
final_arima_fit <- trainvalidation |>
  model(
    arima_auto = ARIMA(n_releases ~ pdq(1,1,2) + PDQ(1,1,2)),
    later_auto = ARIMA(n_releases, stepwise = F, approx=FALSE),
    mine = ARIMA(n_releases ~ pdq(1,1,1) + PDQ(0,1,0))
  )
final_test_fits <- bind_cols(final_snaive_fit, final_arima_fit)
final_test_forecasts <- final_test_fits |>
  forecast( h = nrow(test))

final_test_forecasts |>
  accuracy(data = test,
           measures = distribution_accuracy_measures) 

final_test_forecasts |>
  autoplot(validation |> bind_rows(test))
