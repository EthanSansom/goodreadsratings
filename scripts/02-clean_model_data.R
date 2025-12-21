# Preamble ---------------------------------------------------------------------
# Purpose: Cleans raw Goodreads reviews data and matches reviews to shortlists novels.
# Author: Ethan Sansom
# Date: 15 December 2025
# Contact: ethan.sansom@mail.utoronto.ca
# License: MIT
# Pre-requisites:
# The following files are downloaded and placed in the correct directory.
# - data/01-raw_data/goodreads_books.json.gz
# - data/01-raw_data/goodreads_book_authors.json.gz
# - data/01-raw_data/goodreads_reviews_dedup.json.gz
# - data/01-raw_data/goodreads_book_works.json.gz
#
# These resources can be found at:
# https://cseweb.ucsd.edu/~jmcauley/datasets/goodreads.html

# Packages ---------------------------------------------------------------------

library(arrow)
library(dplyr)
library(purrr)
library(readr)
library(lubridate)
library(here)

set.seed(123)

# Load Raw Data ----------------------------------------------------------------

finalist_books <- read_csv(here("data/01-raw_data/finalist_books.csv"))
announcement_dates <- read_csv(here("data/01-raw_data/announcement_dates.csv"))

goodreads_books <- open_dataset(
  here("data/01-raw_data/goodreads_books.json.gz"),
  format = "json"
)
goodreads_authors <- open_dataset(
  here("data/01-raw_data/goodreads_book_authors.json.gz"),
  format = "json"
)
goodreads_reviews <- open_dataset(
  here("data/01-raw_data/goodreads_reviews_dedup.json.gz"),
  format = "json"
)
goodreads_works <- open_dataset(
  here("data/01-raw_data/goodreads_book_works.json.gz"),
  format = "json"
)

# Subset Finalist Books --------------------------------------------------------

## Filter the Goodreads books by title (case-intensive)

finalist_books <- finalist_books |> mutate(title_norm = tolower(title))
goodreads_books <- goodreads_books |> mutate(title_norm = tolower(title))

goodreads_finalist_works <- goodreads_books |>
  filter(title_norm %in% unique(finalist_books$title_norm)) |>
  select(authors, title_norm, work_id) |>
  collect()

## Match the remaining Goodreads books by title and author

# Extract the first author (e.g. not the translator)
goodreads_finalist_works <- goodreads_finalist_works |>
  mutate(author_id = map_chr(authors, ~.x[[1, "author_id"]])) |>
  select(-authors)

goodreads_authors_dict <- goodreads_authors |>
  filter(author_id %in% unique(goodreads_finalist_works$author_id)) |>
  select(author_id, author_name = name) |>
  collect()

goodreads_finalist_works <- goodreads_finalist_works |>
  left_join(
    goodreads_authors_dict, 
    by = "author_id",
    relationship = "many-to-one"
  ) |>
  inner_join(
    finalist_books, 
    by = c("title_norm", "author_name"),
    relationship = "many-to-many"
  ) |>
  distinct(title, author_name, author_id, work_id, year, type, category, award) |>
  left_join(
    announcement_dates |>
      select(year, award, winner_date, shortlist_date) |>
      mutate(across(c(winner_date, shortlist_date), dmy)),
    by = c("year", "award"),
    relationship = "many-to-one"
  )

# Each Goodreads `work_id` is associated with a unique novel while each
# `book_id` is associated with a specific edition or format of that novel.
finalist_works_to_books <- goodreads_books |>
  filter(work_id %in% goodreads_finalist_works$work_id) |>
  select(work_id, book_id) |>
  collect()

# Subset Finalist Reviews ------------------------------------------------------

goodreads_finalist_reviews <- goodreads_reviews |>
  filter(book_id %in% finalist_works_to_books$book_id) |>
  select(user_id, book_id, review_id, rating, review_text, date_added) |>
  collect() |>
  mutate(date_added = parse_date_time(date_added, orders = "a b d H M S z Y"))

goodreads_finalist_reviews <- goodreads_finalist_reviews |>
  # Remove reviews with no text
  filter(!is.na(review_text) & review_text != "") |>
  
  # Remove ratings of zero, occur when a user leaves a text rating without a review
  filter(rating != 0 & !is.na(rating)) |>
  
  # Keep the first duplicate review (e.g. a user reviews multiple editions)
  left_join(finalist_works_to_books, by = "book_id") |>
  filter(date_added == min(date_added), .by = c(user_id, work_id))

# Sample Random Reviews --------------------------------------------------------

works_sample <- goodreads_works |>
  filter(!(work_id %in% finalist_works_to_books$work_id)) |>
  slice_sample(n = 10000) |>
  collect()

books_sample <- goodreads_books |>
  filter(work_id %in% works_sample$work_id) |>
  collect() |>
  select(work_id, book_id)

reviews_sample <- goodreads_reviews |>
  inner_join(books_sample, by = "book_id") |>
  
  # Remove reviews with no text
  filter(
    !is.na(review_text), 
    review_text != "", 
    rating != 0, 
    !is.na(rating)
  ) |>
  collect() |>
  
  # Keep the first duplicate review (e.g. a user reviews multiple editions)
  mutate(date_added = parse_date_time(date_added, orders = "a b d H M S z Y")) |>
  filter(date_added == min(date_added), .by = c(user_id, work_id))

# Save -------------------------------------------------------------------------

write_parquet(
  goodreads_finalist_works, 
  here("data/02-analysis_data/finalist_works.parquet")
)
write_parquet(
  finalist_works_to_books, 
  here("data/02-analysis_data/works_to_books.parquet")
)
write_parquet(
  goodreads_finalist_reviews, 
  here("data/02-analysis_data/book_reviews.parquet")
)
write_parquet(
  reviews_sample,
  here("data/02-analysis_data/reviews_sample.parquet")
)
