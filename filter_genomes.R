library(dplyr)
library(stringi)
library(stringr)
library(readr)

# Function to convert dates in YYYY-MM / YYYY formats to YYYY-MM-DD with placeholders for unknowns month and/or day
convert_date_ymd <- function(date_str) {
  if (is.null(date_str) || !is.character(date_str) || date_str == "") {
    return(NA_character_) # Return NA for invalid inputs
  }
  
  if (grepl("^\\d{4}-\\d{2}-\\d{2}$", date_str)) {
    return(date_str) # Return date if in YYYY-MM-DD format
  } else if (grepl("^\\d{4}-\\d{2}$", date_str)) {
    return(paste0(date_str, "-XX")) # Append -XX for day if in YYYY-MM format
  } else if (grepl("^\\d{4}$", date_str)) {
    return(paste0(date_str, "-XX-XX")) # Append -XX-XX for month and day if only year is provided
  } else {
    return(NA_character_) # Return NA for non-matching formats
  }
}

SpeciesName <- c("West Nile", "West Nile virus", "Orthoflavivirus nilensense")
SpeciesName2 <- c("Orthoflavivirus nilensense")

wnv_genomes<-BVBRC_filovirade %>% select(Genome.Name, Genus, Species,
                                   Genome.Status, Genome.Quality,
                                   Strain, Genome.Quality.Flags, 
                                   Publication,GenBank.Accessions, Size, 
                                   Isolation.Source,
                                   Isolation.Country, Collection.Year, 
                                   Collection.Date, Geographic.Location,
                                   Host.Common.Name,
                                   Host.Group) %>% 
  filter(Strain!="" & Genome.Status=="Complete" & Isolation.Country!="" & 
           Collection.Year!="NA") %>%
  filter(str_detect(Genome.Name,paste(SpeciesName, collapse ="|"))) %>%
  mutate(Strain2=paste(GenBank.Accessions, Strain, sep = "_")) %>%
  distinct(Strain, .keep_all = TRUE) %>%
  mutate(date2 = lapply(Collection.Date, convert_date_ymd))

wnv_genomes <- wnv_genomes %>%
  mutate(date2 = as.character(date2))

# Now attempt to write the dataframe to a CSV file
write.csv(wnv_genomes, "westnileVirus2.txt", row.names = FALSE)
write_delim(wnv_genomes, "westnileVirus3.txt", delim = ",", col_names = TRUE)
