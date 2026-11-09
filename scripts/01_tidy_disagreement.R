# 01_tidy_disagreement.R
# Tidies the representative survey data (one sheet per demographic group) and
# constructs the disagreement index for each group.
#
# Input:  data/raw/Anchoring Filters.xlsx
# Output: data/processed/<group>_star.RData and <group>_star.csv
#
# Run with the working directory set to the Econlet_Rep folder.

library(tidyverse)
library(openxlsx)

# Settings ----------------------------------------------------------------
raw_file    <- "data/raw/Anchoring Filters.xlsx"
out_dir     <- "data/processed"
start_date  <- as.Date("2019-02-05")
cal_end     <- as.Date("2022-04-03")  # end of the calendar used to show missing days
sample_end  <- as.Date("2022-05-31")  # end of the estimation sample

# One sheet per group, in sheet order
groups <- c("Age",         # Alter
            "JobPosition", # Berufliche Stellung
            "ProfEdu",     # Berufsbildung
            "PopDensity",  # Bevölkerungsdichte
            "EastWest",    # Ost/West
            "SchEdu",      # Schulbildung
            "EmplStatus",  # Beschäftigungsstatus
            "Gender",      # Geschlecht
            "Kids",        # Kinder im Haushalt
            "Marital",     # Familienstand
            "Total",       # Gesamtergebnis
            "RegionalPP",  # Regionale Kaufkraft
            "Religion",    # Religionszugehörigkeit
            "PartyPref")   # Wahlabsicht - Bund

# Translations of German category labels
job_labels <- c("Weiß nicht / keine Angabe" = "Don't know (NA)",
                "Nicht berufstätig"         = "Not employed",
                "Arbeiter"                  = "Blue-collar",
                "Angestellter"              = "Employee",
                "Leitender Angestellter"    = "Manager",
                "Beamter"                   = "Civil servant",
                "Selbstständig"             = "Self-employed")

school_labels <- c("Weiß nicht / keine Angabe" = "Don't know (NA)",
                   "Ohne Abschluss"            = "None",
                   "Noch in Ausbildung"        = "In education",
                   "Berufsausbildung"          = "Vocational training",
                   "Studium oder höher"        = "Degree")

gender_labels <- c("Frauen" = "Female", "Männer" = "Male")

age_levels <- c("18 - 29", "30 - 39", "40 - 49", "50 - 64", "65 +")

# Full calendar, used to make missing days visible in the csv files
calendar <- tibble(Day = seq(start_date, cal_end, by = "day"))

# Main loop ---------------------------------------------------------------
for (i in seq_along(groups)) {
  group <- groups[i]

  df <- read.xlsx(raw_file, sheet = i, startRow = 6,
                  colNames = TRUE, rowNames = FALSE)
  df$Tag <- as.Date(df$Tag, "%d.%m.%Y")

  colnames(df) <- c("Day",          # Tag
                    "Participants", # Teilnehmer
                    "Sample",       # Zeitraum
                    group,          # demographic group
                    "A", "B", "C", "D", "N")  # answer shares, N = don't know

  df <- df %>%
    select(1:9) %>%
    mutate(CI = C + 0.5 * B) %>%
    # Shares excluding "don't know"
    mutate(A_star = A / (1 - N), B_star = B / (1 - N),
           C_star = C / (1 - N), D_star = D / (1 - N)) %>%
    mutate(CI_star = CI / (1 - N),
           MU      = A_star + 0.5 * B_star - D_star) %>%
    # Disagreement: variance of the answer distribution around its mean MU,
    # with answer values 1, 0.5, 0 and -1 for A, B, C and D
    mutate(Dis_sq = A_star * (1 - MU)^2 + B_star * (0.5 - MU)^2 +
                    C_star * (-MU)^2   + D_star * (-1 - MU)^2) %>%
    mutate(Dis = sqrt(Dis_sq)) %>%
    filter(Day >= start_date & Day <= sample_end) %>%
    arrange(Day)

  df[[4]] <- as.factor(df[[4]])

  if (group == "Age") {
    df <- df %>% mutate(Age = ordered(Age, levels = age_levels))
  } else if (group == "JobPosition") {
    df <- df %>% mutate(JobPosition = as.factor(plyr::revalue(JobPosition, job_labels)))
  } else if (group == "SchEdu") {
    df <- df %>% mutate(SchEdu = as.factor(plyr::revalue(SchEdu, school_labels)))
  } else if (group == "Gender") {
    df <- df %>% mutate(Gender = as.factor(plyr::revalue(Gender, gender_labels)))
  }

  # Version with all calendar days, so missing days show up as NA
  df_na <- full_join(calendar, df, by = "Day")
  df_na[[4]] <- as.integer(df_na[[4]])

  save(df, file = file.path(out_dir, paste0(group, "_star.RData")))
  write.csv(df_na, file = file.path(out_dir, paste0(group, "_star.csv")),
            row.names = FALSE)
}
