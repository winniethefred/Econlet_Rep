# 02_plots.R
# Plots for the paper update: CI, answer A vs. CPI inflation, disagreement,
# don't-know share (total and by gender).
#
# Input:  data/processed/<group>_star.RData (from 01_tidy_disagreement.R)
#         data/raw/cpi_germany_052022.csv
# Output: output/plots/*.eps
#
# Run with the working directory set to the Econlet_Rep folder.

library(tidyverse)
library(zoo)

# Settings ----------------------------------------------------------------
groups <- c("Age", "JobPosition", "ProfEdu", "PopDensity", "EastWest",
            "SchEdu", "EmplStatus", "Gender", "Kids", "Marital", "Total",
            "RegionalPP", "Religion", "PartyPref")

# Regime break dates (first and last entry are the sample limits)
break_dates <- as.Date(c("2019-02-05", "2019-06-15", "2019-12-24",
                         "2020-05-06", "2021-05-02", "2022-05-31"))

plot_w    <- 9
plot_h    <- 4
text_size <- 16
coeff     <- 10   # scaling of the second axis in the CPI plot

# Data --------------------------------------------------------------------
for (group in groups) {
  load(file.path("data/processed", paste0(group, "_star.RData")))
  assign(paste0("df_", group), df)
  rm(df)
}

# CPI data (monthly, mid-month dates)
cpi <- read.csv2("data/raw/cpi_germany_052022.csv")
cpi_months <- seq(as.Date("2019-01-15"), as.Date("2022-05-15"), by = "month")
cpi <- tibble(Day = cpi_months, cpi[, 3:5])

# Merge CPI and survey data
jointdf <- full_join(select(df_Total, Day, A), select(cpi, Day, pi_yoy), by = "Day") %>%
  mutate(A = A * 100) %>%
  # The first 10 rows have no CPI value (hard-coded; check if the data change)
  mutate(pi_interpol = c(rep(NA, 10), na.approx(pi_yoy)))

# Helpers -----------------------------------------------------------------
regime_lines <- geom_vline(xintercept = break_dates[2:5],
                           linetype = "dashed", colour = "gray30")

# Single-series plot with regime lines
plot_series <- function(data, y) {
  ggplot(data) +
    geom_line(aes(x = Day, y = {{ y }}), linewidth = 0.75, colour = "steelblue4") +
    regime_lines +
    xlab(element_blank()) + ylab(element_blank()) + expand_limits(y = 0) +
    scale_x_date(date_labels = "%m-%Y") +
    theme_bw() +
    theme(axis.text = element_text(size = text_size))
}

save_eps <- function(name) {
  ggsave(file.path("output/plots", name), device = "eps",
         width = plot_w, height = plot_h, dpi = 900)
}

# CI ----------------------------------------------------------------------
# Regime means of CI, hard-coded. The third regime (Dec 2019 to May 2020, mean 41)
# is not drawn, as in the original plot.
mean_CI <- c(46, 44, 41, 35)
ci_segments <- tibble(x = break_dates[1:4], xend = break_dates[2:5], y = mean_CI) %>%
  slice(-3)

plot_series(df_Total, CI * 100) +
  geom_segment(data = ci_segments, aes(x = x, xend = xend, y = y, yend = y),
               colour = "firebrick", linewidth = 0.6)
save_eps("CI.eps")

# CPI inflation vs. share of answer A ---------------------------------------
ggplot(jointdf[11:1192, ], aes(x = Day)) +
  geom_line(aes(y = pi_interpol), linewidth = 0.75, colour = "firebrick3") +
  geom_line(aes(y = A / coeff),   linewidth = 0.75, colour = "steelblue4") +
  regime_lines +
  xlab(element_blank()) +
  scale_y_continuous(name = "CPI Inflation",
                     sec.axis = sec_axis(~ . * coeff, name = "Share of A")) +
  scale_x_date(date_labels = "%m-%Y") +
  theme_bw() +
  theme(legend.position = "bottom",
        axis.text    = element_text(size = text_size),
        axis.title.y = element_text(size = text_size))
save_eps("Answer_A_CPI.eps")

# Disagreement ------------------------------------------------------------
plot_series(df_Total, Dis_sq)
save_eps("Disagreement.eps")

# Don't-know share, total ---------------------------------------------------
plot_series(df_Total, N * 100)
save_eps("N_Answer.eps")

# Don't-know share by gender -------------------------------------------------
ggplot(df_Gender) +
  geom_line(aes(x = Day, y = N * 100, colour = Gender), linewidth = 0.75) +
  regime_lines +
  xlab(element_blank()) + ylab(element_blank()) + expand_limits(y = 0) +
  scale_x_date(date_labels = "%m-%Y") +
  scale_colour_manual(
    values = c("#9780d6", "#544776"),
    labels = c(expression(paste("Female ", " ", " ", (A^F))),
               expression(paste("Male ",   " ", " ", (A^M))))) +
  theme_bw() +
  theme(legend.position = "bottom",
        legend.text = element_text(size = text_size, margin = margin(r = 1, unit = "cm")),
        axis.text = element_text(size = text_size),
        legend.spacing.x = unit(0.5, "cm"),
        legend.key.width = unit(1, "cm"),
        legend.key.height = unit(1, "cm")) +
  guides(colour = guide_legend(title = element_blank(),
                               override.aes = list(linewidth = 1.5),
                               nrow = 1, ncol = 2))
save_eps("N_Answer_Gender.eps")
