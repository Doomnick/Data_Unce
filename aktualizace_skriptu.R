# Funkce pro kontrolu a instalaci knihoven
install_if_needed <- function(package_name) {
  if (!requireNamespace(package_name, quietly = TRUE)) {
    install.packages(package_name, repos = "https://cran.rstudio.com/")
  }
}

# Seznam knihoven, které chceme zkontrolovat a případně nainstalovat
packages <- c("jsonlite", "httr", "fs", "rstudioapi")

# Instalace knihoven, pokud nejsou nainstalovány
lapply(packages, install_if_needed)

library(jsonlite)
library(httr)
library(fs)
library(rstudioapi)

# Nastavení
repo <- "Doomnick/Data_Unce"
branch <- "main"
sha_file <- file.path(getwd(), "last_sha.txt")
repo_url <- "https://github.com/Doomnick/Data_Unce/archive/refs/heads/main.zip"

# Pomocná funkce – zjisti aktuální složku skriptu
get_script_dir <- function() {
  if (requireNamespace("rstudioapi", quietly = TRUE) &&
      rstudioapi::isAvailable()) {
    path <- rstudioapi::getActiveDocumentContext()$path
    if (!is.null(path) && nzchar(path)) return(dirname(normalizePath(path)))
  }
  return(normalizePath(getwd()))
}

local_dir <- get_script_dir()

# Získání SHA posledního commitu z GitHubu
get_latest_sha <- function(repo, branch = "main") {
  url <- sprintf("https://api.github.com/repos/%s/commits/%s", repo, branch)
  res <- httr::GET(url)
  if (res$status_code != 200) stop("Nepodařilo se získat SHA z GitHubu.")
  json <- content(res, as = "text", encoding = "UTF-8")
  data <- fromJSON(json)
  return(data$sha)
}

# Načti a ulož SHA
get_saved_sha <- function(path) {
  if (file_exists(path)) readLines(path, warn = FALSE) else NULL
}
save_sha <- function(sha, path) {
  writeLines(sha, path)
}

# --- Kontrola a případná aktualizace ---
latest_sha <- get_latest_sha(repo, branch)
saved_sha <- get_saved_sha(sha_file)

if (is.null(saved_sha) || saved_sha != latest_sha) {
  message("🔄 Nová verze k dispozici. Spouštím aktualizaci...")
  
  # Dočasný ZIP a extrakce
  temp_zip <- tempfile(fileext = ".zip")
  temp_extract <- tempfile()
  
  # Stáhni ZIP z GitHubu
  download.file(repo_url, temp_zip, mode = "wb")
  unzip(temp_zip, exdir = temp_extract)
  
  # Cesta k rozbalené složce
  unzipped_dir <- file.path(temp_extract, "Data_Unce-main")
  
  # Soubory k aktualizaci
  update_files <- c("report.Rmd", "spusteni.R")
  
  for (file_name in update_files) {
    file_path <- file.path(unzipped_dir, file_name)
    target_path <- file.path(local_dir, file_name)
    
    if (file_exists(file_path)) {
      file.copy(file_path, target_path, overwrite = TRUE)
      message("✅ Aktualizován: ", file_name)
    } else {
      message("⚠️ Soubor nenalezen v repozitáři: ", file_name)
    }
  }
  
  # Ulož nový SHA
  save_sha(latest_sha, sha_file)
  message("📌 SHA uložen: ", latest_sha)
  
} else {
  message("✅ Máš aktuální verzi. Není třeba aktualizovat.")
}