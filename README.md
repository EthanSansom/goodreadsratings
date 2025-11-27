# The Impact of Winning the Pulitzer Prize on Goodreads Ratings of Novels, 2011–2017

## Overview

This paper analyzes the impact of receiving a Pulitzer Prize on the Goodreads.com ratings of novels between 2011 and 2017. Using the 2017 Goodreads dataset (UCSD Book Graph), it conducts a limited replication of “The Paradox of Publicity: How Awards Can Negatively Affect the Evaluation of Quality” by Balázs Kovács and Amanda J. Sharkey (2014), who found that, between 2007 and 2011, award announcements decreased the ratings given to winning novels on Goodreads. To replicate their approach, a difference-in-differences model is used to estimate how readers’ ratings change before and after a novel receives a Pulitzer Prize.

## File Structure

The repo is structured as:

-   `data/raw_data` contains a subset of the Goodreads review data obtained from the [UCSD Book Graph](https://sites.google.com/eng.ucsd.edu/ucsdbookgraph/reviews).
-   `data/analysis_data` contains the cleaned dataset that was constructed.
-   `model` contains fitted models. 
-   `other` contains relevant literature, details about LLM chat interactions, and sketches.
-   `paper` contains the files used to generate the paper, including the Quarto document and reference bibliography file, as well as the PDF of the paper. 
-   `scripts` contains the R scripts used to simulate, download and clean data.

## Statement on LLM usage

Aspects of the code were written with the help of the Github Copilot.
