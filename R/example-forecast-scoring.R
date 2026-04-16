## Load all required libraries
## If you don't have one, install the library and then load
library(fpp3)
library(here)
library(hubData)
library(hubUtils)
library(tidyverse)
library(scoringutils)

here::i_am("R/example-forecast-scoring.R")

## Set the relative path from your working directory to where the hub is
local_hub_path <- here("../ATSF2026/")

## Read the observed truth data
observed_data <- connect_target_timeseries(local_hub_path) |> 
  collect()

## Identify dates for the validation time period
reference_dates <- local_hub_path |> 
  read_config("tasks") |> 
  get_round_ids()
validation_dates <- reference_dates[which(reference_dates<'2017-05-13')]

## This is where you would produce your forecasts for the validation dates using
## your current best model (or some iteration of it) and save the csvs into the
## correct local hub path





## Read every forecast file in the hub
hub_forecasts <- connect_hub(local_hub_path) |>
  collect_hub() |>
  as_tibble()

## Output model options
hub_forecasts |> pull(model_id) |> unique()

## Select model results for model of choice
## Also make sure that you are only evaluating things from validation time period
## When you are testing, you would change the model_id to whateve you called your model
model_fcasts <- hub_forecasts |> 
  filter(model_id == 'hist-avg',
         origin_date %in% validation_dates)


## Keep quantile forecasts, join observations, and rename columns for scoringutils
quantile_forecasts <- model_fcasts |>
  filter(output_type == "quantile") |>
  left_join(
    observed_data,
    by = c("location", "target_end_date", "target")
  ) |>
  filter(!is.na(observation)) |>
  transmute(
    model = model_id,
    origin_date,
    location,
    target,
    horizon,
    target_end_date,
    observed = observation,
    predicted = value,
    quantile_level = as.numeric(output_type_id)
  )

## Tell scoringutils which rows belong to one forecast
scoring_input <- quantile_forecasts |>
  as_forecast_quantile(
    forecast_unit = c(
      "model",
      "origin_date",
      "location",
      "target",
      "horizon",
      "target_end_date"
    )
  )

## Score forecasts using WIS and interval coverage
score_metrics <- get_metrics(
  scoring_input,
  select = c("wis", "interval_coverage_50", "interval_coverage_90")
)
forecast_scores <- score(scoring_input, metrics = score_metrics)

## Summarize for WIS and PIC
## Remember lower is better for WIS, and PIC you want values that equal the nominal value
## Meaning roughly 0.5 for the 50% prediction interval and .95 for the 95% interval
forecast_scores |>
  summarise_scores(by = "model")

## Now you would go back to the forecast code, alter your 
## model and produce new forecasts with the next variation to test
## Make sure to document each of the model iterations you try alongside their WIS so you 
## don't forget which variant gets the best score



