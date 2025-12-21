# Preamble ---------------------------------------------------------------------
# Purpose: Simulates Goodreads reviews data of shortlisted novels.
# Author: Ethan Sansom
# Date: 21 December 2025
# Contact: ethan.sansom@mail.utoronto.ca
# License: MIT

# Packages ---------------------------------------------------------------------

library(dplyr)
library(purrr)
library(readr)
library(lubridate)

# Load Raw Data ----------------------------------------------------------------

finalist_books <- read_csv("data/01-raw_data/finalist_books.csv")
announcement_dates <- read_csv("data/01-raw_data/announcement_dates.csv")

finalist_books <- finalist_books |> 
  left_join(announcement_dates, by = c("year", "award")) |>
  mutate(winner_date = dmy(winner_date)) |>
  filter(between(year, 2010, 2016))

# Simulate Reviews -------------------------------------------------------------

## Helper Functions ------------------------------------------------------------

simulate_winner_rating <- function(n, period = c("pre-award", "post-award")) {
  # Assume slightly lower reviews post award for winners: ~0.2 stars according 
  # to Kovacs and Sharkey (2014).
  if (period == "pre-award") {
    # Implies a mean rating of 3.9
    prob <- c(0.05, 0.1, 0.15, 0.3, 0.4)
  } else {
    # Implies a mean rating of 3.7
    prob <- c(0.05, 0.1+0.05, 0.15+0.05, 0.3-0.05, 0.4-0.05)
  }
  sample(1L:5L, n, replace = TRUE, prob = prob)
}

simulate_finalist_rating <- function(n) {
  # Assume same trend as winners. For simplicity, assume trend is flat.
  simulate_winner_rating(n, period = "pre-award")
}

simulate_uid <- function(n) {
  symbols <- c(letters, as.character(0:9))
  map_chr(seq(n), ~ paste(sample(symbols, 20, replace = TRUE), collapse = ""))
}

simulate_text <- function(n) {
  map_chr(seq(n), ~ paste(sample(words, sample(10:20, 1), replace = FALSE), collapse = " "))
}

simulate_datetime <- function(n, min_date, max_date) {
  dates <- seq(from = as.Date(min_date), to = as.Date(max_date), by = "day")
  sample(dates, n, replace = TRUE) +
    dhours(sample(0:23, n, replace = TRUE)) + 
    dminutes(sample(0:59, n, replace = TRUE))
}

## Simulate --------------------------------------------------------------------

reviews_pre <- 10
reviews_post <- 20
reviews_total <- reviews_pre + reviews_post

set.seed(123)

# Use `finalist_books`, which contains each novel and the date of it's award
# announcement, as the base. We simulate a number of reviews per novel and
# per period (post-award and pre-award).
simulated_reviews <- finalist_books |>
  distinct(title, type, winner_date) |>
  # Each novel is associated with a unique identifier
  mutate(work_id = simulate_uid(n())) |>
  reframe(
    # Each version of a novel (e.g. e-book, paperback, etc.) has a unique ID
    book_id = sample(simulate_uid(10), reviews_total, replace = TRUE),
    
    # Reviews are also uniquely identified by an ID
    review_id = simulate_uid(reviews_total),
    review_text = simulate_text(reviews_total),
    date_added = c(
      # Simulate reviews prior to the award announcement for each work
      simulate_datetime(reviews_pre, winner_date - dyears(1), max_date = winner_date),
      # Simulate reviews post announcement
      simulate_datetime(reviews_post, winner_date, as.Date("2017-12-01"))
    ),
    rating = if (type == "finalist") {
      simulate_finalist_rating(reviews_total) 
    } else {
      c(
        simulate_winner_rating(reviews_pre, "pre-award"),
        simulate_winner_rating(reviews_post, "post-award")
      )
    },
    .by = work_id
  ) |>
  mutate(user_id = simulate_uid(n()), .by = book_id) |>
  select(user_id, book_id, review_id, rating, review_text, date_added, work_id)

# Save -------------------------------------------------------------------------

write_csv(
  simulated_reviews,
  "data/00-simulated_data/simulated_reviews.csv"
)
