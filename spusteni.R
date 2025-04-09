# Funkce pro kontrolu a instalaci knihoven
install_if_needed <- function(package_name) {
  if (!requireNamespace(package_name, quietly = TRUE)) {
    install.packages(package_name, repos = "https://cran.rstudio.com/")
  }
}

packages <- c("rmarkdown", "pacman", "rstudioapi", "tcltk", "lubridate", "progressr", "bookdown",
              "ggplot2", "tidyverse", "officer", "tinytex", "dplyr", "knitr", "shiny", "readxl", "shinyFiles", "later")

invisible(lapply(packages, install_if_needed))

suppressWarnings(library(pacman))
suppressWarnings(library(rstudioapi))
library(tcltk)
suppressPackageStartupMessages(suppressWarnings(library(lubridate)))
suppressPackageStartupMessages(suppressWarnings(library(progressr)))
pacman::p_load(readxl, dplyr, stringr, parallel, future.apply, rmarkdown, readr, shiny, shinyFiles)

rm(list = ls())

if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  script_path <- rstudioapi::getActiveDocumentContext()$path
  script_dir <- dirname(script_path)
} else {
  script_dir <- normalizePath(getwd())
}

select_file_and_schoolcode <- function() {
  file_env <- new.env()
  
  ui <- fluidPage(
    titlePanel("Výběr vstupního souboru a kódu školy"),
    shinyFilesButton("file", "Vyberte soubor s daty (.xlsx)", "Vyberte .xlsx soubor", multiple = FALSE),
    verbatimTextOutput("filepath"),
    textInput("school", "Zadejte kód školy:", value = ""),
    actionButton("ok", "Potvrdit")
  )
  
  server <- function(input, output, session) {
    volumes <- shinyFiles::getVolumes()()
    program_slozka <- getwd()
    volumes <- c("Program Directory" = dirname(program_slozka), volumes)
    names(volumes) <- gsub(".*\\((.*)\\).*", "\\1", names(volumes))
    
    default_root <- "Program Directory"
    default_path <- basename(program_slozka)
    
    shinyFileChoose(
      input, "file",
      roots = volumes,
      filetypes = c("xlsx", "xls"),
      defaultRoot = default_root,
      defaultPath = default_path
    )
    
    observeEvent(input$file, {
      if (!is.null(input$file)) {
        parsed_path <- parseFilePaths(volumes, input$file)
        if (nrow(parsed_path) > 0) {
          file_env$selected_file <- parsed_path$datapath[1]
          output$filepath <- renderText(file_env$selected_file)
        }
      }
    })
    
    observeEvent(input$ok, {
      if (is.null(file_env$selected_file)) {
        showModal(modalDialog("❌ Nevybral jste soubor.", easyClose = TRUE))
      } else if (input$school == "") {
        showModal(modalDialog("❌ Nezadali jste kód školy.", easyClose = TRUE))
      } else {
        file_env$school_code <- input$school
        file_env$data_dir <- dirname(file_env$selected_file)
        file_env$output_dir <- file.path(file_env$data_dir, input$school)
        dir.create(file_env$output_dir, showWarnings = FALSE, recursive = TRUE)
        
        # Zobraz hlášku o úspěchu
        showModal(modalDialog(
          title = "✅ Hotovo",
          "Soubor a kód školy byly úspěšně zadány. Generuji reporty...",
          footer = NULL
        ))
        
        # Počkej chvíli a pak zavři aplikaci
        later::later(function() {
          session$sendCustomMessage("closeWindow", list())
          stopApp()
        }, delay = 2)  # 2 sekundy
      }
    })
  }
  
  runApp(shinyApp(ui, server), launch.browser = TRUE)
  
  return(list(
    datapath = file_env$selected_file,
    school_code = file_env$school_code,
    output_dir = file_env$output_dir
  ))
}

file_info <- select_file_and_schoolcode()
selected_file <- file_info$datapath
school_code <- file_info$school_code
output_dir <- file_info$output_dir

data <- read_excel(selected_file)

required_columns <- c(
  "ID", "Name", "PL_physical", "PL_psychological", "PL_Social", "PL_Cognitive", "PL_overall",
  "AFFEXX_overall_report", "COG_T14", "COG_T16", "COG_T17",
  "Trial1_time_s", "Trial2_time_s", "Trial1_timescore", "Trial2_timescore",
  "Trial1_quality", "Trial2_quality", "Trial1_allscore", "Trial2_allscore",
  "Sex_(F/M)", "Age_forCAMSAdatetesting", "Beeptest_totalshuttle",
  "LPA_per_day_min", "MVPA_per_day_min", "PA_evalu",
  "Height_cm", "Weight_kg", "Fat%", "Fat_evalu", "ATH_%", "ATH_evalu", "Water_%", "Water_evalu"
)

missing_columns <- setdiff(required_columns, colnames(data))
if (length(missing_columns) > 0) {
  stop("Chybějící sloupce v datasetu: ", paste(missing_columns, collapse = ", "))
}

filtered_data <- data %>%
  filter(str_starts(ID, school_code)) %>%
  mutate(Row_Num = row_number())

invalid_rows <- filtered_data %>%
  filter(apply(select(., all_of(required_columns)), 1, anyNA)) %>%
  select(ID, Name, Row_Num)

valid_data <- filtered_data %>%
  filter(!apply(select(., all_of(required_columns)), 1, anyNA))

plan(multisession)

generate_report <- function(row) {
  df <- valid_data[row, ]
  temp_output_file <- file.path(output_dir, paste0(df$ID, "_", df$Name, "_", Sys.getpid(), ".pdf"))
  final_output_file <- file.path(output_dir, paste0(df$ID, "_", df$Name, ".pdf"))
  Sys.setenv(RSTUDIO_PANDOC = "C:/Program Files/RStudio/resources/app/bin/quarto/bin/tools")
  
  result <- tryCatch({
    rmarkdown::render(
      input = file.path(script_dir, "report.rmd"),
      output_file = temp_output_file,
      intermediates_dir = tempdir(),
      knit_root_dir = script_dir,
      params = list(df = df),
      envir = new.env(),
      clean = TRUE,
      quiet = TRUE
    )
    file.rename(temp_output_file, final_output_file)
    list(status = "success", file = final_output_file, id = df$ID, name = df$Name)
  }, error = function(e) {
    list(status = "failed", error = conditionMessage(e), id = df$ID, name = df$Name)
  })
  return(result)
}

cat("⏳ Spouštím paralelní generování reportů, vyčkejte...\n")

results <- future_lapply(1:nrow(valid_data), generate_report)
cat("✅ Generování dokončeno.\n")

completed_reports <- Filter(function(x) x$status == "success", results)
failed_reports <- Filter(function(x) x$status == "failed", results)

log_file <- file.path(output_dir, paste0("log_", school_code, "_", format(Sys.time(), "%Y-%m-%d_%H-%M"), ".txt"))

log_content <- c(
  "Generování reportů dokončeno",
  paste0("📂 Složka s reporty: ", output_dir),
  paste0("✅ Úspěšné: ", length(completed_reports)),
  if (length(completed_reports) > 0) paste(sapply(completed_reports, function(x) paste(x$id, x$name)), collapse = "\n") else "Žádné",
  paste0("❌ Chyby: ", length(failed_reports)),
  if (length(failed_reports) > 0) paste(sapply(failed_reports, function(x) paste(x$id, x$name, "- Chyba:", x$error)), collapse = "\n") else "Žádné",
  paste0("⚠️ Vyřazeno kvůli NA: ", nrow(invalid_rows)),
  if (nrow(invalid_rows) > 0) paste(apply(invalid_rows, 1, paste, collapse = " - "), collapse = "\n") else ""
)

write_lines(log_content, log_file)
message("📄 Log uložen do: ", log_file)