main_lib <- .libPaths()[1]
if (!dir.exists(main_lib)) dir.create(main_lib, recursive = TRUE)
.libPaths(main_lib)

# Seznam balíčků
packages <- c(
  "jsonlite", "httr", "fs", "rstudioapi", "ggplot2", "tidyverse",
  "officer", "dplyr", "knitr", "tcltk", "lubridate", "progressr", "pacman", "tinytex"
)

# Instalace chybějících balíčků
missing <- setdiff(packages, rownames(installed.packages()))
if (length(missing) > 0) {
  install.packages(missing, dependencies = TRUE)
}

# Instalace TinyTeX
if (!requireNamespace("tinytex", quietly = TRUE)) {
  install.packages("tinytex")
}
tinytex::install_tinytex()