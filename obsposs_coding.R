# Handling "obsposs" species for the atlas
# Obsposs species are ones where H is not meaningful - so Observed, H, and S are lumped into a separate category denoting the species was present (but status as a local breeder is questionable)
# See "Other Observations" with gull maps in "The Second Atlas of Breeding Birds in Ohio"

# The Process:
# 1. SQL pulls all records in the obsposs window for selected species (this is in EBD format if you want to pull via some other method)
    # https://github.com/nmanich/eBird_to_postgreSQL/blob/master/Queries/obsposs%20species.sql
# 2. R code to recode O H and S in obsposs window become to obsposs (and C1 and C2 cats become 1.5) (this code below)

# Then you can do a variety of things with this code:
# (A) Export several columns (breeding code, breeding category) with just the new changed obsposs records
# (B) Export several columns (breeding code, breeding category) but with the obsposs records integrated into the breeding code and category columns 
# (C) Add as a new column in final database with the new obsposs records
# (D) Add columns in the final database with the obsposs records integrated into breeding codes
# (E) Export a full EBD with both C and D
# (F) Export both C and D for only the species we are making obsposs changes to.

# UNRESOLVED: Need code for block_evidence.R to make a map showing obsposs records
# Easiest fix would be to overwrite E with H and change label?
# But maybe easy enough to make a separate script to use output file from this code

# Remember that Whooping Crane is a obsposs species but does not appear in EBD download!

library(dplyr)
library(plyr)

# Pull Obsposs records from database in EBD format https://github.com/nmanich/eBird_to_postgreSQL/blob/master/Queries/obsposs%20species.sql
# load records from obsposs window
obsposs <- read.csv("obsposs_records.csv")

#create duplicate category column
obsposs$new_breeding_category <- obsposs$breeding_category

#create duplicate code column
obsposs$new_breeding_code <- obsposs$breeding_code

#change breeding categories C1 and C2 and blank to new category 1.5
obsposs <- obsposs%>%mutate(new_breeding_category=ifelse(new_breeding_category=="C1","C1.5",new_breeding_category))
obsposs <- obsposs%>%mutate(new_breeding_category=ifelse(new_breeding_category=="C2","C1.5",new_breeding_category))
obsposs <- obsposs%>%mutate(new_breeding_category=ifelse(new_breeding_category=="","C1.5",new_breeding_category))

#change no code, F, H, S in this window to new code E (= Exists but unsure if local)
obsposs <- obsposs%>%mutate(new_breeding_code=ifelse(new_breeding_code=="F","E",new_breeding_code))
obsposs <- obsposs%>%mutate(new_breeding_code=ifelse(new_breeding_code=="H","E",new_breeding_code))
obsposs <- obsposs%>%mutate(new_breeding_code=ifelse(new_breeding_code=="S","E",new_breeding_code))
obsposs <- obsposs%>%mutate(new_breeding_code=ifelse(new_breeding_code=="","E",new_breeding_code))

# (A) in Intro
# Optional -- Export out a small table with just OBSID plus the new code and category codes.
# These are the obsposs records that differ from the eBird treatment
export <- obsposs[, c("global_unique_identifier","new_breeding_category","new_breeding_code")]
write.csv(export, file= "obsposschangedrecords.csv", row.names=FALSE)

## Adding the columns into the main eBird table

# This would be how you would vlookup this table into the main eBird table
# load main atlas data
ebird <- read.delim("ebd_US-WI_201501_201912_relApr-2021.txt", quote = "", as.is = TRUE)

# Optional - restrict to atlas portal
ebird  <- ebird[ebird$PROJECT.CODE == "EBIRD_ATL_WI", ]

# edit column names from export
colnames(export) <- c("GLOBAL.UNIQUE.IDENTIFIER", "OBSPOSS.BREEDING.CATEGORY", "OBSPOSS.BREEDING.CODE")

# (C) in Intro
# join changed records
ebird <- join(ebird, export, by = "GLOBAL.UNIQUE.IDENTIFIER")

## make new breeding columns with all records and obsposs records together in same column

#copy original breeding columns

ebird$BREEDING.CATEGORY.WITH.OBSPOSS <- ebird$BREEDING.CATEGORY
ebird$BREEDING.CODE.WITH.OBSPOSS <- ebird$BREEDING.CODE

# (D) in intro
# replace those values in breeding columns with the non-NA values from obsposs column
  
ebird$BREEDING.CATEGORY.WITH.OBSPOSS <- ifelse(is.na(ebird$OBSPOSS.BREEDING.CATEGORY), ebird$BREEDING.CATEGORY.WITH.OBSPOSS, ebird$OBSPOSS.BREEDING.CATEGORY)

ebird$BREEDING.CODE.WITH.OBSPOSS <- ifelse(is.na(ebird$OBSPOSS.BREEDING.CODE), ebird$BREEDING.CODE.WITH.OBSPOSS, ebird$OBSPOSS.BREEDING.CODE)

# (E) in Intro
# Optional export full EBD with 2 columns showing obsposs category and code, and 2 columns showing obsposs codes integrated with others.
# write.csv(ebird, file= "EBDwithobsposs.csv", row.names=FALSE)

# (B) in Intro
# Optional -- Export out a small table with just OBSID plus the new code and category codes integrated
# export2 <- ebird[, c("GLOBAL.UNIQUE.IDENTIFIER","BREEDING.CATEGORY.WITH.OBSPOSS","BREEDING.CODE.WITH.OBSPOSS")]
# write.csv(export2, file= "New_breeding_codes_and_cats_with_integrated_obsposs_values.csv", row.names=FALSE)

# Subset to just obsposs species
justobspossspecies <- ebird[grepl("Spotted Sandpiper|Ring-billed Gull|Herring Gull|Great Black-backed Gull|Laughing Gull|Caspian Tern|Forster's Tern|Common Tern|Double-crested Cormorant|American White Pelican|Great Blue Heron|Great Egret|Snowy Egret|Cattle Egret|Black-crowned Night-Heron|Yellow-crowned Night-Heron|Turkey Vulture|Whooping Crane", ebird$COMMON.NAME), ]

# (F) in Intro
# Export just obsposs species
write.csv(justobspossspecies, file= "JustObspossSpecies_New_breeding_codes_and_cats_with_integrated_obsposs_values.csv", row.names=FALSE)

