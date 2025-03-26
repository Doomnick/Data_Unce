README: Generování reportů ze souboru

Popis skriptu:

Tento skript načte dataset ze souboru data.xlsx (nebo jiný název - řádek 11 skriptu), umožní uživateli zadat kód školy a následně vygeneruje reporty pro probandy odpovídající danému kódu školy. Reporty jsou generovány v paralelním režimu a ukládány do samostatné složky pojmenované podle zadaného kódu školy.

Požadavky:

R ve verzi 4.0 nebo novější
RStudio (doporučeno, ale není nutné)
Nainstalované knihovny: pacman, rstudioapi, tcltk, readxl, dplyr, stringr, parallel, future.apply, rmarkdown, readr, ggplot2, tidyverse, officer, knitr
Pokud nejsou knihovny nainstalovány, můžete je nainstalovat pomocí následujícího příkazu:

install.packages(c("pacman", "rstudioapi", "tcltk", "readxl", "dplyr", "stringr", "parallel", "future.apply", "rmarkdown", "readr", "ggplot2", "tidyverse", "officer", "knitr"))

Jak spustit skript:

Ujistěte se, že soubory "data.xlsx", "logo.png" a skripty "spuštění.R" a "report.rmd" jsou ve stejné složce.
Otevřete skript v RStudiu.
Klikněte na tlačítko Source v pravém horním rohu editoru skriptu.
Po spuštění se zobrazí dialogové okno, ve kterém je třeba zadat kód školy.
Skript načte dataset a vyfiltruje pouze probandy odpovídající zadanému kódu školy.
Pro vybrané probandy se vygenerují individuální reporty ve formátu PDF.
Po dokončení generování se zobrazí informační okno a vytvoří se log soubor log.txt.
Co se děje během běhu skriptu
Skript načte data ze souboru data.xlsx.
Ověří, zda dataset obsahuje všechny požadované sloupce.
Požádá uživatele o zadání kódu školy.
Vyfiltruje data na základě zadaného kódu školy.
Identifikuje řádky s chybějícími hodnotami a vyřadí je.
Spustí paralelní generování reportů na základě report.rmd.
Po dokončení generování zobrazí informační okno a uloží log soubor log.txt se souhrnem úspěšných a neúspěšných reportů.

Výstupy skriptu:

Vygenerované reporty ve formátu PDF ve složce odpovídající zadanému kódu školy.
Log soubor log.txt, který obsahuje:
Počet úspěšně vygenerovaných reportů.
Počet chyb během generování.
Seznam řádků, které byly vyřazeny kvůli chybějícím datům.

Řešení problémů:

Chybějící sloupce: Pokud dataset neobsahuje všechny požadované sloupce, skript se zastaví s chybovou zprávou.
Neexistující kód školy: Pokud žádní probandi neodpovídají zadanému kódu školy, skript se zastaví.
Chyby během generování: Pokud některé reporty nelze vygenerovat, jejich ID a chybové hlášení budou uvedeny v log.txt.

Kontakt:

Pokud narazíte na problémy, kontaktujte autora: Dominik Kolinger, 604774455