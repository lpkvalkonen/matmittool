# Load packages
library(dplyr)

# Load data
load("data_1to15.RData")

# Filter data based on selected columns
data <- data_1to15 %>% select(Päämatkakohde,Asuinalue,
                        Matkan_tarkoitus,
                        Ikäryhmä,
                        Matkaseura,
                        Majoitus)

profiles_data <- data %>%
  count(across(everything())) %>%
  arrange(desc(n)) #%>%


# Save profiles as data
save(profiles_data, file = "profiles_data.RData")
