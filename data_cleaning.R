#-------------------------------------------------------------------------------
### Load packages
#-------------------------------------------------------------------------------

library(dplyr)
library(tidyr)
library(knitr)
library(xtable)
library(fastDummies)
library(jsonlite)
library(purrr)
library(r2country)



#-------------------------------------------------------------------------------
### Load data
#-------------------------------------------------------------------------------

data <-
  read.csv(
    "matkailijamittari_data.csv",
    header = TRUE,
    sep = ",",
    fill = NA
  )



#-------------------------------------------------------------------------------
### Data preparations and selections
#-------------------------------------------------------------------------------

# Paste m before PkKunta variable (for factor coding purposes)
data$PkKunta <- paste("m", data$PkKunta, sep = "")
data$Mk1Kunta <- paste("m", data$Mk1Kunta, sep = "")
data$Mk2Kunta <- paste("m", data$Mk2Kunta, sep = "")
data$Mk3Kunta <- paste("m", data$Mk3Kunta, sep = "")



#-------------------------------------------------------------------------------
# Mutate variable types
#-------------------------------------------------------------------------------

data <- mutate(
  data,
  Kuukausi = as.factor(Kuukausi),
  Neljannes = as.factor(Neljannes),
  VkonPv = as.factor(VkonPv),
  RajaPiste = as.factor(RajaPiste),
  Hsatama = as.factor(Hsatama),
  AsMaa = as.factor(AsMaa),
  Alue = as.factor(Alue),
  Kansal = as.factor(Kansal),
  Sukup =  as.factor(Sukup),
  Ikaryhma = as.factor(Ikaryhma),
  Kulkuvaline = as.factor(Kulkuvaline),
  MatTyyp = as.factor(MatTyyp),
  MatTark = as.factor(MatTark),
  MuutMaat = as.factor(MuutMaat),
  PkKunta = as.factor(PkKunta),
  PkMaakunta = as.factor(PkMaakunta),
  PkSuuralue = as.factor(PkSuuralue),
  PkRyhma = as.factor(PkRyhma),
  Mk1Kunta = as.factor(Mk1Kunta),
  Mk1Maakunta = as.factor(Mk1Maakunta),
  Mk1Suuralue = as.factor(Mk1Suuralue),
  Mk1Ryhma = as.factor(Mk1Ryhma),
  Mk2Kunta = as.factor(Mk2Kunta),
  Mk2Maakunta = as.factor(Mk2Maakunta),
  Mk2Suuralue = as.factor(Mk2Suuralue),
  Mk2Ryhma = as.factor(Mk2Ryhma),
  Mk3Kunta = as.factor(Mk3Kunta),
  Mk3Maakunta = as.factor(Mk3Maakunta),
  Mk3Suuralue = as.factor(Mk3Suuralue),
  Mk3Ryhma = as.factor(Mk3Ryhma),
  Majoitus = as.factor(Majoitus),
  Pake = as.factor(Pake),
  PakeA = as.factor(PakeA),
  PakePL = as.factor(PakePL),
  PakeMPS = as.factor(PakeMPS),
  PakePMM = as.factor(PakePMM),
  SegLuonto = as.factor(SegLuonto),
  SegUrhei = as.factor(SegUrhei),
  SegHyvin = as.factor(SegHyvin),
  SegKult = as.factor(SegKult),
  SegKaupu = as.factor(SegKaupu),
  SegTapah = as.factor(SegTapah),
  SegOstos = as.factor(SegOstos),
  SegKierto = as.factor(SegKierto),
  SegEiMit = as.factor(SegEiMit),
  Yli50kmSuom = as.factor(Yli50kmSuom),
  Yli50Auto = as.factor(Yli50Auto),
  Yli50Juna = as.factor(Yli50Juna),
  Yli50Lento = as.factor(Yli50Lento),
  Yli50Linja = as.factor(Yli50Linja),
  Yli50Laiva = as.factor(Yli50Laiva),
  Yli50Taksi = as.factor(Yli50Taksi),
  Seura = as.factor(Seura),
  SeuraAlle7v = as.factor(SeuraAlle7v),
  Seura8_15v = as.factor(Seura8_15v)
)



#-------------------------------------------------------------------------------
# Select the variables to be used in modeling
#-------------------------------------------------------------------------------

data <- cbind(
  data %>% dplyr::select(
    EURYht,
    Kuukausi,
    Neljannes,
    Sukup,
    Ikaryhma,
    KestoYo,
    PkYot,
    Mk1Yot,
    Mk2Yot,
    Mk3Yot,
    Kulkuvaline,
    MatTyyp,
    MatTark,
    MuutMaat,
    PkKunta,
    PkSuuralue,
    Mk1Kunta,
    Mk2Kunta,
    Mk3Kunta,
    Majoitus,
    Kulkuvaline,
    SegLuonto,
    SegUrhei,
    SegHyvin,
    SegKult,
    SegKaupu,
    SegTapah,
    SegOstos,
    SegKierto,
    SegEiMit,
    Yli50kmSuom,
    EnsiVarausKk,
    AsMaa,
    Seura,
    PainoQ,
    Vuosi,
    MatTark,
    VkonPv,
    RajaPiste,
    CO2Yht
  )
)



#-------------------------------------------------------------------------------
### Data handling
#-------------------------------------------------------------------------------

# Assume that "m" and "mXX" in PkKunta indicates unknown destination
data %>% filter(data$PkKunta == "m") %>% select(PkKunta, PkSuuralue)
data %>% filter(data$PkKunta == "mXX") %>% select(PkKunta, PkSuuralue)
sum(data$PkKunta == "m") + sum(data$PkKunta == "mXX") == sum(is.na(data$PkSuuralue)) # Check

# Code them as NAs
data$PkKunta[data$PkKunta == "m"] <- NA
data$PkKunta[data$PkKunta == "mXX"] <- NA
data$PkKunta <- droplevels(data$PkKunta)

# Rename factor levels in Suuralue
data[c("PkSuuralue")] <-
  lapply(data[c("PkSuuralue")],
         function(x) {
           levels(x) <-
             c("Pääkaupunkiseutu",
               "Rannikko ja saaristo",
               "Järvi-Suomi",
               "Lappi ja Kuusamo")
           return(x)
         })

# Add another level into PkSuuralue: Helsinki
data$PkSuuralue <- factor(data$PkSuuralue,
                          levels = c("Helsinki", levels(data$PkSuuralue)))

# Add Helsinki level
data$PkSuuralue[data$PkKunta == "m091"] <- "Helsinki"

# Indicator variables
# If no other visits -> MkYot = 0
data$Mk1Yot <- ifelse(data$Mk1Kunta == "m", 0, data$Mk1Yot)
data$Mk2Yot <- ifelse(data$Mk2Kunta == "m", 0, data$Mk2Yot)
data$Mk3Yot <- ifelse(data$Mk3Kunta == "m", 0, data$Mk3Yot)



#-------------------------------------------------------------------------------
### Filter data
#-------------------------------------------------------------------------------

# Complete cases only
data <- na.omit(data)

# Consider trips where EURYht > 0
data <- data %>% filter(EURYht > 0)


# Daily visits

# If visited another destinations
data$Vierailut_muissa_kohteissa <-
  ifelse((
    data$Mk1Yot >= 0 & data$Mk1Kunta != "m" |
      data$Mk2Yot >= 0 &
      data$Mk2Kunta != "m" |
      data$Mk3Yot >= 0 &
      data$Mk3Kunta != "m"
  ),
  1,
  0
  ) %>% as.factor()

data$Yöpymiset_muissa_kohteissa <-
  data$Mk1Yot + data$Mk2Yot + data$Mk3Yot

# Split the data for 1-15 nights
data_1to15 <- data %>% filter(KestoYo > 0 & KestoYo <= 15)



#-------------------------------------------------------------------------------
### Change factor level names
#-------------------------------------------------------------------------------

data_1to15$Sukup <- factor(
  data_1to15$Sukup,
  levels = c("1", "2", "3", "4"),
  labels = c("Mies",
             "Nainen",
             "Muu",
             "En halua kertoa")
)


data_1to15$Ikaryhma <- factor(
  data_1to15$Ikaryhma,
  levels = c("1", "2", "3", "4"),
  labels = c(
    "15-24 vuotiaat",
    "25-44 vuotiaat",
    "45-64 vuotiaat",
    "vähintään 65-vuotiaat"
  )
)

data_1to15$Kulkuvaline <- factor(
  data_1to15$Kulkuvaline,
  levels = c("1", "2"),
  labels = c("Laiva",
             "Lentokone")
)

data_1to15$MatTark <- factor(
  data_1to15$MatTark,
  levels = c("1", "2", "3", "4", "5", "6", "7", "9"),
  labels = c(
    "Loma, vapaa-ajanvietto tai virkistäytyminen",
    "Tuttavien tai sukulaisten tapaaminen",
    "Opiskelu",
    "Joku muu tarkoitus",
    "Kokous- tai työmatka ei-suomalaisen työnantajan palveluksessa",
    "Konferenssi tai kongressi tai messut",
    "Suomalaisen työnantajan palveluksessa tehtävä työ Suomessa",
    "Joku muu työhön liittyvä syy"
  )
)


data_1to15$Majoitus <- factor(
  data_1to15$Majoitus,
  levels = c("1", "2", "3", "4", "5", "6", "7", "8", "9"),
  labels = c(
    "Hotelli tai hostelli",
    "Leirintäalue (maksullinen esim. teltta, asuntoauto, asuntovaunu, mökki)",
    "Vuokramökki tai -asunto (yksityiseltä tai välittäjältä vuokrattu, esimerkiksi airbnb tai booking.com)",
    "Tuttavien tai sukulaisten luona (sis. couchsurfing)",
    "Oma asunto, mökki tai lomaosake",
    "Työnantajan järjestämä asunto",
    "Muu majoitustapa",
    "En yöpynyt Suomessa",
    "En osaa sanoa"
  )
)

data_1to15$Kuukausi <- factor(
  data_1to15$Kuukausi,
  levels = c("1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"),
  labels = c(
    "Tammikuu",
    "Helmikuu",
    "Maaliskuu",
    "Huhtikuu",
    "Toukokuu",
    "Kesäkuu",
    "Heinäkuu",
    "Elokuu",
    "Syyskuu",
    "Lokakuu",
    "Marraskuu",
    "Joulukuu"
  )
)

data_1to15$SegLuonto <- factor(
  data_1to15$SegLuonto,
  levels = c("0", "1"),
  labels = c("Ei",
             "Kyllä")
)

data_1to15$SegHyvin <- factor(data_1to15$SegHyvin,
                              levels = c("0", "1"),
                              labels = c("Ei",
                                         "Kyllä"))

data_1to15$SegKult <- factor(data_1to15$SegKult,
                             levels = c("0", "1"),
                             labels = c("Ei",
                                        "Kyllä"))

data_1to15$SegKaupu <- factor(data_1to15$SegKaupu,
                              levels = c("0", "1"),
                              labels = c("Ei",
                                         "Kyllä"))

data_1to15$SegTapah <- factor(data_1to15$SegTapah,
                              levels = c("0", "1"),
                              labels = c("Ei",
                                         "Kyllä"))

data_1to15$SegKierto <- factor(
  data_1to15$SegKierto,
  levels = c("0", "1"),
  labels = c("Ei",
             "Kyllä")
)

data_1to15$SegUrhei <- factor(data_1to15$SegUrhei,
                              levels = c("0", "1"),
                              labels = c("Ei",
                                         "Kyllä"))

data_1to15$SegOstos <- factor(data_1to15$SegOstos,
                              levels = c("0", "1"),
                              labels = c("Ei",
                                         "Kyllä"))

data_1to15$Yli50kmSuom <- factor(
  data_1to15$Yli50kmSuom,
  levels = c("1", "2"),
  labels = c("Kyllä",
             "Ei")
)

data_1to15$Seura <- factor(
  data_1to15$Seura,
  levels = c("1", "2", "3", "4"),
  labels = c(
    "Matkustan yksin",
    "Matkustan kahdestaan puolison tai kumppanin kanssa",
    "Matkustan perheen, sukulaisten tai ystävien kanssa",
    "Muu"
  )
)

data_1to15$MuutMaat <- factor(data_1to15$MuutMaat,
                              levels = c("1", "2"),
                              labels = c("Kyllä",
                                         "Ei"))

data_1to15$Vierailut_muissa_kohteissa <- factor(
  data_1to15$Vierailut_muissa_kohteissa,
  levels = c("0", "1"),
  labels = c("Ei",
             "Kyllä")
)

data_1to15 <- data_1to15 %>%
  rename(
    'Euroa' = 'EURYht',
    'Yöpymiset' = 'KestoYo',
    'Neljännes' = 'Neljannes',
    'Asuinmaa' = 'AsMaa',
    'Sukupuoli' = 'Sukup',
    'Ikäryhmä' = 'Ikaryhma',
    'Kulkuväline' = 'Kulkuvaline',
    'Matkan_tarkoitus' = 'MatTark',
    'Päämatkakohde' = 'PkSuuralue',
    'Majoitus' = 'Majoitus',
    'Luontomatkailu' = 'SegLuonto',
    'Urheilumatkailu' = 'SegUrhei',
    'Hyvinvointimatkailu' = 'SegHyvin',
    'Kulttuurimatkailu' = 'SegKult',
    'Kaupunkimatkailu' = 'SegKaupu',
    'Osallistui_tapahtumiin' = 'SegTapah',
    'Ostosmatkailu' = 'SegOstos',
    'Kiertomatkailu' = 'SegKierto',
    'Yli_50km_matkoja_Suomessa' = 'Yli50kmSuom',
    'Matkaseura' =  'Seura',
    'Ensi_varaus_kk_ennen' = 'EnsiVarausKk',
    'CO2_kg' = 'CO2Yht'
  )


#-------------------------------------------------------------------------------
### Add country/continent information
#-------------------------------------------------------------------------------

# Full names for countries and municipalities

# Countries
countries_full_names <- fromJSON(
  "https://api.stat.fi/classificationservice/open/api/classifications/v2/classifications/valtio_2_20120101/classificationItems?content=data&meta=max&lang=en&format=json",
  flatten = TRUE
)

countries_names <- countries_full_names %>%
  transmute(code = code,
            country_fi = map_chr(classificationItemNames,
                                 ~ .x$name[.x$lang == "en"]))

# Combine
data_1to15 <- data_1to15 %>%
  left_join(countries_names, by = c("Asuinmaa" = "code")) %>%
  mutate(Asuinmaa = country_fi) %>%
  select(-country_fi)


# Add continent: Europe vs Other
countries
country_names # country names
country_continent# continent countries
country_names$ID == country_continent$ID

countr_cont <-
  left_join(country_names, country_continent, by = "ID")

# Add into data
data_1to15 <-
  left_join(data_1to15, countr_cont, by = c("Asuinmaa" = "name")) %>%
  mutate(Asuinalue = ifelse(continent == "Europe", "Eurooppa", "Muu kuin Eurooppa")) %>%
  select(-c(ID, continent))
data_1to15$Asuinalue <- as.factor(data_1to15$Asuinalue)

str(data)

#-------------------------------------------------------------------------------
### Select the variables to the final data
#-------------------------------------------------------------------------------

data_1to15 <- data_1to15 %>% select(
  Vuosi,
  Neljännes,
  Euroa,
  Päämatkakohde,
  Yöpymiset,
  Majoitus,
  Kulkuväline,
  Matkan_tarkoitus,
  Sukupuoli,
  Ikäryhmä,
  Luontomatkailu,
  Kulttuurimatkailu,
  Kaupunkimatkailu,
  Osallistui_tapahtumiin,
  Ostosmatkailu,
  Yli_50km_matkoja_Suomessa,
  Ensi_varaus_kk_ennen,
  Matkaseura,
  CO2_kg,
  Asuinalue,
  Vierailut_muissa_kohteissa,
  Yöpymiset_muissa_kohteissa,
  MuutMaat,
  Urheilumatkailu,
  Hyvinvointimatkailu,
  Kiertomatkailu
)




#-------------------------------------------------------------------------------
### Save the cleaned data
#-------------------------------------------------------------------------------
save(data_1to15, file = "data_1to15.RData")
