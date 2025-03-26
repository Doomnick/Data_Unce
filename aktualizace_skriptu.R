library(shiny)
library(rstudioapi)
library(fs)

aktualizovat_app <- F
# ---- AUTOMATICKÁ AKTUALIZACE ZE ZIPU NA GITHUBU ----
repo_url <- "https://github.com/Doomnick/WingateApp/archive/refs/heads/main.zip"

get_script_dir <- function() {
  if (requireNamespace("rstudioapi", quietly = TRUE) &&
      rstudioapi::isAvailable()) {
    path <- rstudioapi::getActiveDocumentContext()$path
    if (!is.null(path) && nzchar(path)) return(dirname(normalizePath(path)))
  }
  return(normalizePath(getwd()))
}

local_dir <- get_script_dir()

# Dočasný ZIP soubor a rozbalovací složka
temp_zip <- tempfile(fileext = ".zip")
temp_extract <- tempfile()

# Stáhni ZIP z GitHubu
download.file(repo_url, temp_zip, mode = "wb")

# Rozbal dočasně
unzip(temp_zip, exdir = temp_extract)

# Cesta ke složce s rozbaleným obsahem (např. "WingateApp-main")
unzipped_dir <- file.path(temp_extract, "WingateApp-main")

# Přepiš .R a .Rmd soubory, které již existují v lokální složce
files_to_copy <- list.files(unzipped_dir, pattern = "\\.(R|Rmd)$", recursive = TRUE, full.names = TRUE)

for (file in files_to_copy) {
  relative_path <- path_rel(file, start = unzipped_dir)
  
  # Pokud nemáme přepisovat app.R, přeskočíme ho
  if (!aktualizovat_app && basename(relative_path) == "app.R") {
    message("⏭️ Přeskočeno (aktualizovat_app = FALSE): ", relative_path)
    next
  }
  
  target_path <- file.path(local_dir, relative_path)
  
  # Vytvoř cílovou složku, pokud ještě neexistuje
  dir.create(dirname(target_path), recursive = TRUE, showWarnings = FALSE)
  
  # Kopíruj soubor
  file.copy(file, target_path, overwrite = TRUE)
  message("✅ Aktualizován nebo vytvořen: ", relative_path)
}