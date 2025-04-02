suppressWarnings(library(pacman))
suppressWarnings(library(rstudioapi))
library(tcltk)
suppressPackageStartupMessages(suppressWarnings(library(lubridate)))
suppressPackageStartupMessages(suppressWarnings(library(progressr)))


rm(list = ls())
pacman::p_load(readxl, dplyr, stringr, parallel, future.apply, rmarkdown, readr)

#ahoj2
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  script_path <- rstudioapi::getActiveDocumentContext()$path
  script_dir <- dirname(script_path)
} else {
  script_dir <- normalizePath(getwd())
}


plan(multisession)  


invisible_root <- tktoplevel()
tkwm.withdraw(invisible_root)  # Skryje okno, ale umožní použít jako parent

# Nastavení okna jako vždy navrchu (topmost)
tcl("wm", "attributes", invisible_root, topmost = TRUE)

# Výběr souboru (okno bude mít prioritu)
selected_file <- tclvalue(tkgetOpenFile(
  title = "Vyberte soubor s daty (data.xlsx)",
  initialdir = script_dir,
  filetypes = "{{Excel Files} {.xlsx}} {{All files} *}",
  parent = invisible_root
))

# Zruš parent po výběru
tkdestroy(invisible_root)

# Pokud nebyl soubor vybrán, ukonči skript
if (selected_file == "") {
  stop("❌ Nebyl vybrán žádný vstupní soubor. Ukončuji skript.")
} else {
  message("📄 Vybraný soubor s daty: ", selected_file)
}

# Načtení dat
data <- read_excel(selected_file)

# Explicitní seznam sloupců použitých v reportu
required_columns <- c(
  "ID", "Name", "PL_physical", "PL_psychological", "PL_Social", "PL_Cognitive", "PL_overall",
  "AFFEXX_overall_report", "COG_T14", "COG_T16", "COG_T17",
  "Trial1_time_s", "Trial2_time_s", "Trial1_timescore", "Trial2_timescore",
  "Trial1_quality", "Trial2_quality", "Trial1_allscore", "Trial2_allscore",
  "Sex_(F/M)", "Age_forCAMSAdatetesting", "Beeptest_totalshuttle",
  "LPA_per_day_min", "MVPA_per_day_min", "PA_evalu",
  "Height_cm", "Weight_kg", "Fat%", "Fat_evalu", "ATH_%", "ATH_evalu", "Water_%", "Water_evalu"
)

# Kontrola chybějících sloupců
missing_columns <- setdiff(required_columns, colnames(data))
if (length(missing_columns) > 0) {
  stop("Chybějící sloupce v datasetu: ", paste(missing_columns, collapse = ", "))
}

# Zadání kódu školy
school_code <- tclVar("")

dlg <- tktoplevel()
tkwm.title(dlg, "Zadejte kód školy")

# Získání rozměrů obrazovky
screen_width <- as.integer(tkwinfo("screenwidth", dlg))
screen_height <- as.integer(tkwinfo("screenheight", dlg))

# Nastavení velikosti okna
win_width <- 300
win_height <- 120

# Výpočet středu obrazovky
x_pos <- (screen_width - win_width) %/% 2
y_pos <- (screen_height - win_height) %/% 2

# Nastavení pozice okna na střed
tkwm.geometry(dlg, paste0(win_width, "x", win_height, "+", x_pos, "+", y_pos))

# Rám pro centrování obsahu
frame <- tkframe(dlg)
tkgrid(frame, row = 0, column = 0)
tkgrid.columnconfigure(dlg, 0, weight = 1)
tkgrid.rowconfigure(dlg, 0, weight = 1)

# Nastavení sloupců pro centrování
tkgrid.columnconfigure(frame, 0, weight = 1)
tkgrid.columnconfigure(frame, 1, weight = 1)

# Centrovaný textový label
label <- tklabel(frame, text = "Kód školy:", justify = "center")
tkgrid(label, row = 0, column = 0, columnspan = 2, pady = 10, sticky = "nsew")

# Centrované vstupní pole
entry <- tkentry(frame, textvariable = school_code, justify = "center")
tkgrid(entry, row = 1, column = 0, columnspan = 2, pady = 5, sticky = "ew")

# Centrované tlačítko OK
ok_button <- tkbutton(frame, text = "OK", command = function() tkdestroy(dlg))
tkgrid(ok_button, row = 2, column = 0, columnspan = 2, pady = 10, sticky = "ew")

tkwait.window(dlg)  # Čekání na zadání vstupu

# Výsledek
school_code <- tclvalue(school_code)

# Filtrace probandů podle kódu školy
filtered_data <- data %>%
  filter(str_starts(ID, school_code))  

if (nrow(filtered_data) == 0) {
  stop("Žádní probandi neodpovídají zadanému kódu školy.")
}
# Přidání čísla řádku
filtered_data <- filtered_data %>%
  mutate(Row_Num = row_number())

# Identifikace nekompletních řádků
invalid_rows <- filtered_data %>%
  filter(apply(select(., all_of(required_columns)), 1, anyNA)) %>%
  select(ID, Name, Row_Num)

# Filtrace pouze validních řádků
valid_data <- filtered_data %>%
  filter(!apply(select(., all_of(required_columns)), 1, anyNA))

# Vytvoření složky pro reporty
data_dir <- dirname(selected_file)
output_dir <- file.path(data_dir, school_code)
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# Generování reportů paralelně
generate_report <- function(row) {
  df <- valid_data[row, ]  
  
  # Unikátní název souboru během generování
  temp_output_file <- file.path(output_dir, paste0(df$ID, "_", df$Name, "_", Sys.getpid(), ".pdf"))
  
  # Finální název souboru (bez čísla procesu)
  final_output_file <- file.path(output_dir, paste0(df$ID, "_", df$Name, ".pdf"))
  
  result <- tryCatch({
    rmarkdown::render(
      input = file.path(script_dir, "report.rmd"),
      output_file = temp_output_file,  # Dočasný soubor
      intermediates_dir = tempdir(),   # Každý proces má svůj vlastní dočasný adresář
      knit_root_dir = script_dir,      # Nastavení správného pracovního adresáře
      params = list(df = df),
      envir = new.env(),
      clean = TRUE,
      quiet = TRUE
    )
    
    # Po úspěšném renderování přejmenovat soubor na finální název
    file.rename(temp_output_file, final_output_file)
    
    # 🔥 Odstranění dočasných souborů po generování
    temp_files <- list.files(
      path = tempdir(),  
      pattern = paste0(df$ID, "_", df$Name, ".*\\.log$"), 
      full.names = TRUE
    )
    
    if (length(temp_files) > 0) {
      file.remove(temp_files[file.exists(temp_files)])  # Smaže pouze existující soubory
    }
    
    list(status = "success", file = final_output_file, id = df$ID, name = df$Name)
  }, error = function(e) {
    list(status = "failed", error = conditionMessage(e), id = df$ID, name = df$Name)
  })
  
  return(result)
}

cat("⏳ Generování reportů spuštěno...\n")

# Zahájíme paralelní zpracování reportů ve future
gen_future <- future::future({
  future_lapply(1:nrow(valid_data), function(i) {
    generate_report(i)
  })
})

# Mezitím tiskneme tečky jako indikátor běhu
while (!future::resolved(gen_future)) {
  cat(".")
  flush.console()
  Sys.sleep(2)
}

# Až vše hotovo, získáme výsledky a vypíšeme info
results <- future::value(gen_future)

cat("\n✅ Generování dokončeno.\n")


# Roztřídění výsledků
completed_reports <- Filter(function(x) x$status == "success", results)
failed_reports <- Filter(function(x) x$status == "failed", results)

# Uložení logu s úspěšnými a neúspěšnými generacemi
log_file <- file.path(data_dir, paste0("log_", school_code, "_", format(Sys.time(), "%Y-%m-%d_%H-%M"), ".txt"))

num_completed <- length(completed_reports)
num_failed <- length(failed_reports)
num_invalid_rows <- nrow(invalid_rows)

log_content <- c(
  "Generování reportů dokončeno",
  "",
  paste0("📂 Složka s reporty: ", output_dir),  # Přidá zobrazení cesty k souborům pod hlavičku
  "",
  paste0("✅ Celkový počet úspěšně vygenerovaných reportů: ", num_completed),
  "Úspěšně vygenerované reporty (ID, Jméno):",
  if (num_completed > 0) {
    paste(sapply(completed_reports, function(x) paste(x$id, x$name)), collapse = "\n")
  } else {
    "Žádné"
  },
  "",
  paste0("⚠️ Celkový počet chyb při generování reportů: ", num_failed),
  "❌ Chyby při generování reportů:",
  if (num_failed > 0) {
    paste(sapply(failed_reports, function(x) paste(x$id, x$name, "- Chyba:", x$error)), collapse = "\n")
  } else {
    "Žádné"
  },
  "",
  paste0("⏳ Celkový počet vyřazených řádků kvůli chybějícím hodnotám: ", num_invalid_rows),
  if (num_invalid_rows > 0) {
    paste0("⚠️ Vyřazené řádky kvůli chybějícím hodnotám:\n",
           paste(invalid_rows$Row_Num, invalid_rows$ID, invalid_rows$Name, sep = " - ", collapse = "\n"))
  } else {
    "✅ Všechny řádky byly kompletní."
  }
)

write_lines(log_content, log_file)

msg_box <- tktoplevel()
tkwm.title(msg_box, "Informace")

# Získání rozměrů obrazovky
screen_width <- as.integer(tkwinfo("screenwidth", msg_box))
screen_height <- as.integer(tkwinfo("screenheight", msg_box))

# Nastavení velikosti okna (zvětšeno pro zobrazení cesty)
win_width <- 500  # Zvětšeno pro delší cesty
win_height <- 150  # Lehce zvětšeno na výšku

# Výpočet středu obrazovky
x_pos <- (screen_width - win_width) %/% 2
y_pos <- (screen_height - win_height) %/% 2

# Nastavení pozice okna na střed
tkwm.geometry(msg_box, paste0(win_width, "x", win_height, "+", x_pos, "+", y_pos))

# Přidání textu zprávy
frame <- tkframe(msg_box)
tkgrid(frame, row = 0, column = 0, sticky = "nsew")
tkgrid.columnconfigure(msg_box, 0, weight = 1)
tkgrid.columnconfigure(frame, 0, weight = 1)

# Definice zpráv
msg1 <- tklabel(frame, text = "Všechny dostupné reporty byly úspěšně vygenerovány!", justify = "center")
msg2 <- tklabel(frame, text = paste0("Finální soubory: ", output_dir), justify = "center", wraplength = 480)
msg3 <- tklabel(frame, text = "Podrobnosti najdete v souboru 'log.txt'.", justify = "center")

# Přidání prvků do okna
tkgrid(msg1, row = 0, column = 0, pady = 5, sticky = "ew")
tkgrid(msg2, row = 1, column = 0, pady = 5, sticky = "ew")
tkgrid(msg3, row = 2, column = 0, pady = 5, sticky = "ew")

# Přidání tlačítka OK (zvětšeno)
ok_button <- tkbutton(frame, text = "OK", width = 12, height = 2, command = function() tkdestroy(msg_box))
tkgrid(ok_button, row = 3, column = 0, pady = 10)

tkwait.window(msg_box)
