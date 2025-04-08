# Ujisti se, že existuje user-level knihovna
user_lib <- Sys.getenv("R_LIBS_USER")
if (!dir.exists(user_lib)) dir.create(user_lib, recursive = TRUE)
.libPaths(user_lib)

# Seznam balíčků
packages <- c(
  "jsonlite", "httr", "fs", "rstudioapi", "ggplot2", "tidyverse",
  "officer", "dplyr", "knitr", "tcltk", "lubridate", "progressr", "pacman", "tinytex"
)

missing <- setdiff(packages, rownames(installed.packages()))
if (length(missing) > 0) {
  install.packages(missing, dependencies = TRUE)
}

if (!requireNamespace("tinytex", quietly = TRUE)) {
  install.packages("tinytex")
}

tinytex::install_tinytex()