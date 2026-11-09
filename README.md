# Econlet_Rep

Replication code for the disagreement index and the figures of the paper [Inflation target credibility in times of high inflation](https://doi.org/10.1016/j.econlet.2022.110930) by Winnie Coleman and Dieter Nautz

Show more.

## Folder structure

```
Econlet_Rep/
  scripts/
    01_tidy_disagreement.R   tidies the survey data, builds the disagreement index
    02_plots.R               produces the figures
  data/
    raw/                     input files (see below)
    processed/               written by script 01
  output/plots/              written by script 02 (EPS)
```

## Data to put in data/raw/

- `Anchoring Filters.xlsx`: representative survey data, one sheet per demographic group (14 sheets, order as in `groups` in script 01)
- `cpi_germany_052022.csv`: monthly German CPI inflation, January 2019 to May 2022

## How to run

1. Set the working directory to the `Econlet_Rep` folder.
2. Run `scripts/01_tidy_disagreement.R`, then `scripts/02_plots.R`.

Required R packages: tidyverse, openxlsx, plyr (only for `revalue`), zoo.

## Variables

- `A`, `B`, `C`, `D`: shares of the four answer categories; `N`: share of "don't know"
- `*_star`: shares excluding "don't know", e.g. `A_star = A / (1 - N)`
- `CI = C + 0.5 * B`
- `MU = A_star + 0.5 * B_star - D_star`: mean answer, with answer values 1, 0.5, 0, -1 for A, B, C, D
- `Dis_sq`: variance of the answers around `MU` (disagreement); `Dis` is its square root. The disagreement figure plots `Dis_sq`.

## Outputs

`CI.eps`, `Answer_A_CPI.eps`, `Disagreement.eps`, `N_Answer.eps`, `N_Answer_Gender.eps`
