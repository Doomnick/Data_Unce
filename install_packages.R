# Nastavení CRAN mirroru (nutné pro neinteraktivní režim)
options(repos = c(CRAN = "https://cloud.r-project.org"))

# Získej uživatelskou knihovnu
user_lib <- Sys.getenv("R_LIBS_USER")
cat("Using user library path:", user_lib, "\n")

# Pokud neexistuje, vytvoř ji
if (!dir.exists(user_lib)) dir.create(user_lib, recursive = TRUE)

# Nastav jako hlavní knihovnu pro instalaci
.libPaths(user_lib)

# Seznam balíčků k instalaci
packages <- c(
  "jsonlite", "httr", "fs", "rstudioapi", "ggplot2", "tidyverse",
  "officer", "dplyr", "knitr", "tcltk", "lubridate", "progressr", "pacman", "tinytex"
)

# Instaluj chybějící
missing <- setdiff(packages, rownames(installed.packages()))
if (length(missing) > 0) {
  install.packages(missing, dependencies = TRUE)
}

# Instalace TinyTeX
if (!requireNamespace("tinytex", quietly = TRUE)) {
  install.packages("tinytex")
}
tinytex::install_tinytex()