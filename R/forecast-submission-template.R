## Forecasting Starter Scaffold
## Goal: create naive/mean forecasts in hubverse format without seeing full solutions.

library(fpp3)
library(here)
library(hubData)
library(hubUtils)
library(hubValidations)
library(tidyverse)

here::i_am("R/practice-forecast-starter.R")

# -----------------------------
# Setup
# -----------------------------

# TODO: update this path if needed
local_hub_path <- here('../ATSF2026/')

# Required quantiles for the hub task
quantiles_needed <- c(0.01, 0.025, seq(0.05, 0.95, 0.05), 0.975, 0.99)


# -----------------------------
# Step 1: Gather and inspect data
# -----------------------------

# TODO: connect to target time-series and collect into `wili_ts`
# Suggested functions: connect_target_timeseries(), collect()
# ts_con <- ???
# wili_ts <- ???

# TODO: convert to tsibble with index target_end_date and key location + target
# Suggested functions: as_tsibble()
# wili_tsibble <- ???

# Quick visual check
# TODO: run this after creating `wili_tsibble`
# wili_tsibble |> autoplot()

# -----------------------------
# Step 2: Find required forecast dates
# -----------------------------

# TODO: read task rounds from config and store in `reference_dates`
# Suggested functions: read_config(), get_round_ids()
# reference_dates <- ???

# -----------------------------
# Step 3: Choose a path
# -----------------------------

# TODO: choose one path: "A" (stretch_tsibble batch workflow) or
# "B" (for-loop workflow that saves each date inside the loop)
path_choice <- "A"


# -----------------------------
# Shared helper: save one CSV per origin date
# -----------------------------

save_fcast_csv <- function(df, hub_path) {
  this_model_id <- df$model_id[1]
  this_origin_date <- df$origin_date[1]

  model_folder <- file.path(hub_path, "model-output", this_model_id)
  filename <- paste0(this_origin_date, "-", this_model_id, ".csv")
  results_path <- file.path(model_folder, filename)

  if (!file.exists(model_folder)) {
    dir.create(model_folder, recursive = TRUE)
  }

  write_csv(df |> select(-model_id), file = results_path)
}

# -----------------------------
# Option A: stretch_tsibble batch workflow
# -----------------------------

# A1) Build expanding windows for all origin dates
# Suggested functions: filter(), min(), nrow(), tsibble::stretch_tsibble()
# start_index <- ???
# expanded_wili <- ???

# A2) Generate forecasts for all windows
# Suggested functions: model(), MEAN(), NAIVE(), SNAIVE(), generate()
# fcasts_all <- ???

# A3) Convert ALL simulations to quantiles (pattern provided)
# q_fcasts_all <- fcasts_all |>
#   as_tibble() |>
#   group_by(.id, location, .model, target, target_end_date) |>
#   reframe(enframe(quantile(.sim, quantiles_needed), "quantile", "value")) |>
#   ungroup()

# A4) Format ALL forecasts for hub submission
# Required columns:
# origin_date, location, target, horizon, target_end_date,
# output_type, output_type_id, value, model_id
# Suggested functions: mutate(), min(), difftime(), as.numeric(), as.character(), pmax(), select()
# formatted_fcasts_all <- ???

# A5) Save ALL dates to CSV files
# Suggested functions: filter(), group_by(), group_split(), purrr::map()
# saved_files_all <- ???

# A6) Validate one output file from Option A
# Suggested functions: validate_submission()
# validation_result_a <- ???


# -----------------------------
# Option B: for-loop per-date workflow
# -----------------------------

# B1) Set up loop inputs
# Suggested functions: sort(), unique(), min(), `[`, list()
# loop_dates <- ???
# model_id <- "atsf-loop-starter"
# saved_files_loop <- character()

# B2) For each date, do everything inside the loop:
# - filter training data up to that origin date
# - fit model and simulate
# - convert to quantiles
# - format to hub columns
# - save CSV immediately
# Suggested functions: for(), filter(), model(), MEAN() or NAIVE(), generate(),
# as_tibble(), group_by(), reframe(), enframe(), quantile(), mutate(), select(), save_fcast_csv()
#
# Quantile pattern for each loop iteration:
# q_fcasts_i <- fcasts_i |>
#   as_tibble() |>
#   group_by(origin_date, location, .model, target, target_end_date) |>
#   reframe(enframe(quantile(.sim, quantiles_needed), "quantile", "value")) |>
#   ungroup()
#
# for (this_origin_date in loop_dates) {
#   # training_i <- ???
#   # fcasts_i <- ???
#   # q_fcasts_i <- ???   # use quantile pattern above
#   # formatted_fcasts_i <- ???
#   # save_fcast_csv(formatted_fcasts_i, hub_path = local_hub_path)
#   # saved_files_loop <- c(saved_files_loop, as.character(this_origin_date))
# }

# B3) Validate one output file from Option B
# Suggested functions: validate_submission()
# validation_result_b <- ???

# End of scaffold
