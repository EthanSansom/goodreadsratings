# Preamble ---------------------------------------------------------------------
# Purpose: Test the structural correctness of the simulated Goodreads review data.
# Author: Ethan Sansom
# Date: 21 December 2025
# Contact: ethan.sansom@mail.utoronto.ca
# License: MIT
# Pre-requisites: Run 00-simulate_data.R to generate simulated data.

# Packages ---------------------------------------------------------------------

library(dplyr)
library(purrr)
library(readr)
library(lubridate)
library(here)
library(testthat)

# Load -------------------------------------------------------------------------

simulated_reviews <- read_csv(here("data/00-simulated_data/simulated_reviews.csv"))

# Test -------------------------------------------------------------------------

test_that("All columns `user_id`, `book_id`, `review_id`, `rating`, `review_text`, `date_added`, `work_id` are present.", {
  expect_identical(
    sort(names(simulated_reviews)),
    sort(c("user_id", "book_id", "review_id", "rating", "review_text", "date_added", "work_id"))
  )
})

test_that("All columns have the correct class.", {
  expected_classes <- list(
    "user_id" = "character",
    "book_id" = "character",
    "review_id" = "character",
    "rating" = "numeric",
    "review_text" = "character",
    "date_added" = c("POSIXct", "POSIXt"),
    "work_id" = "character"
  )
  expect_identical(
    map(simulated_reviews, class)[names(expected_classes)],
    expected_classes
  )
})

test_that("Ratings are integers between 1 and 5.", {
  expect_all_true(simulated_reviews$rating %in% 1:5)
})

test_that("Column `review_id` uniquely identifies as observation.", {
  expect_true(n_distinct(simulated_reviews$review_id) == nrow(simulated_reviews))
})

test_that("Works (identified by `work_id`) do not share any `book_id`s.", {
  simulated_reviews |>
    summarize(book_ids = list(unique(book_id)), .by = work_id) |>
    mutate(
      shared_books = map2(book_ids, work_id, ~ intersect(.x, unlist(book_ids[work_id != .y]))),
      has_shared_books = lengths(shared_books) > 0
    ) |>
    pull(has_shared_books) |>
    expect_all_false()
})

test_that("Users can leave only one review per book.", {
  simulated_reviews |>
    mutate(duplicate_reviews = any(duplicated(user_id)), .by = book_id) |>
    pull(duplicate_reviews) |>
    expect_all_false()
})
