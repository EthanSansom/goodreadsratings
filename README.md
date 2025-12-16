# The Impact of Winning a Literary Award on Goodreads Ratings of Novels, 2010-2016

## Overview

This paper analyzes the impact of receiving a Pulitzer Prize on the Goodreads.com ratings of novels between 2010 and 2016. Using the 2017 Goodreads dataset (UCSD Book Graph), it conducts a limited replication of “The Paradox of Publicity: How Awards Can Negatively Affect the Evaluation of Quality” by Balázs Kovács and Amanda J. Sharkey (2014), who found that, between 2007 and 2011, award announcements decreased the ratings given to winning novels on Goodreads. To replicate their approach, a difference-in-differences model is used to estimate how readers’ ratings change before and after a novel receives a Man Booker Prize, National Book Award, PEN/Faulkner Award, or a National Book Critics Circle Award.

To reproduce this analysis, download the following `.json.gz` files from the [UCSD Book Graph](https://sites.google.com/eng.ucsd.edu/ucsdbookgraph/reviews) and ensure they are within the `data/01-raw_data` directory:
- `goodreads_books.json.gz`
- `goodreads_book_authors.json.gz`
- `goodreads_reviews_dedup.json.gz`
- `goodreads_book_works.json.gz`
Then, run the following scripts in order:
- `scripts/01-clean_model_data.R`
- `scripts/02-model_data.R`
- `paper/paper.qmd`

## File Structure

The repo is structured as:

-   `data/raw_data` contains a dataset `finalist_books.csv` containing the set of novels shortlisted for the Man Booker Prize, the National Book Award, the PEN/Faulkner Award, and the National Book Critics Circle Award from 2010-2016. `announcement_dates.csv` contains the date that the shortlisted novels and winning novel was announced for each award.
-   `data/analysis_data` contains cleaned Goodreads reviews subset to shortlisted novels.
-   `model` contains fitted models `ratings_model.rds` and `popularity_model.rds`.
-   `other/llm_usage/usage.txt` contains a copy of a ChatGPT-4 text chat used during the writing of this paper. 
-   `paper` contains the Quarto document and bibliography file used to generate this paper, as well as a copy of the paper `paper.pdf`.
-   `scripts` contains the R scripts used to clean and model the data.

## Statement on LLM usage

Research for this paper was conducted using ChatGPT-4. `other/llm_usage/usage.txt` contains a transcript of the chat.
