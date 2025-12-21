# Preamble ---------------------------------------------------------------------
# Purpose: Models the impact of award-winning on the ratings and popularity of prizewinning novels.
# Author: Ethan Sansom
# Date: 15 December 2025
# Contact: ethan.sansom@mail.utoronto.ca
# License: MIT

# Packages ---------------------------------------------------------------------

library(arrow)
library(dplyr)
library(lubridate)
library(fixest)

# Load Data --------------------------------------------------------------------

finalist_works <- read_parquet("data/02-analysis_data/finalist_works.parquet")
works_to_books <- read_parquet("data/02-analysis_data/works_to_books.parquet")
book_reviews <- read_parquet("data/02-analysis_data/book_reviews.parquet")

finalist_works <- finalist_works |> filter(year <= 2016)

## Matched Pairs ---------------------------------------------------------------

pre_award_reviews <- book_reviews |>
  inner_join(
    finalist_works,
    by = join_by(work_id, date_added < shortlist_date)
  ) |>
  group_by(
    year, award, category, winner_date, shortlist_date, 
    work_id, title, author_name, type
  ) |>
  summarize(
    n_ratings = n(),
    mean_rating = mean(rating)
  ) |>
  ungroup()

distance_mean_rating <- function(mean_rating, type) {
  abs(mean_rating[type == "winner"] - mean_rating)
}

matched_pairs <- pre_award_reviews |>
  group_by(year, award, category) |>
  filter(any(type == "winner")) |>
  mutate(
    winner_distance = distance_mean_rating(mean_rating, type),
    dyad = as.factor(cur_group_id())
  ) |>
  slice_min(winner_distance, n = 2, with_ties = FALSE) |> # 2016 National Book Critics Circle has a tie
  ungroup() |>
  
  # Keep only the first pair a book appears in, if it appears in multiple pairs
  filter(winner_date == min(winner_date), .by = work_id) |>
  filter(n() == 2L, .by = c(year, award, category))

## Reviews ---------------------------------------------------------------------

matched_pairs_reviews <- book_reviews |>
  inner_join(matched_pairs, by = "work_id") |>
  mutate(
    winner = as.integer(type == "winner"),
    post_announcement = as.integer(date_added > winner_date)
  ) |>
  filter(
    sum(post_announcement) >= 1,
    sum(1 - post_announcement) >= 1,
    .by = work_id
  ) |>
  filter(n_distinct(work_id) == 2, .by = dyad)

# Models -----------------------------------------------------------------------

## Ratings ---------------------------------------------------------------------

ratings <- feols(
  rating ~ winner + post_announcement + winner:post_announcement | dyad,
  data = matched_pairs_reviews,
  cluster = "dyad"
)

## Popularity ------------------------------------------------------------------

matched_pairs_counts <- matched_pairs_reviews |>
  group_by(dyad, post_announcement, winner) |>
  summarize(n_reviews = n()) |>
  ungroup()

popularity <- fenegbin(
  n_reviews ~ winner + post_announcement + winner:post_announcement | dyad,
  data = matched_pairs_counts,
  cluster = "dyad"
)

## Parallel Trends -------------------------------------------------------------

pre_trend_data <- matched_pairs_reviews |>
  filter(post_announcement == 0) |>
  mutate(
    time_trend = (date_added - lubridate::as_datetime(winner_date)) / dmonths()
  )

parallel_trends <- feols(
  rating ~ winner * time_trend | dyad,
  data = pre_trend_data,
  cluster = "dyad"
)

## Robustness ------------------------------------------------------------------

## Minimum Reviews
review_mins <- c(50, 100, 200)
for (minimum in review_mins) {
  matched_pairs_reviews_minimums <- matched_pairs_reviews |>
    filter(n() >= minimum, .by = c(work_id, post_announcement)) |>
    filter(n_distinct(work_id) == 2L, .by = c(dyad, post_announcement))
  
  model_minimum <- feols(
    rating ~ winner + post_announcement + winner:post_announcement | dyad, 
    data = matched_pairs_reviews_minimums
  )
  write_rds(
    model_minimum,
    glue::glue("models/ratings_model_k{minimum}.rds")
  )
}

# Save -------------------------------------------------------------------------

write_parquet(
  matched_pairs_reviews,
  "data/02-analysis_data/matched_pairs_reviews.parquet"
)

write_rds(
  ratings,
  "models/ratings_model.rds"
)

write_rds(
  popularity,
  "models/popularity_model.rds"
)

write_rds(
  parallel_trends,
  "models/parallel_trends_model.rds"
)
