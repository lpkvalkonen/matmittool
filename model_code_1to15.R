#-------------------------------------------------------------------------------
### Load packages
#-------------------------------------------------------------------------------
library(brms)
library(dplyr)
library(ggplot2)

#-------------------------------------------------------------------------------
### Load data
#-------------------------------------------------------------------------------
load("data_1to15.RData")

#-------------------------------------------------------------------------------
### Modeling
#-------------------------------------------------------------------------------

# OBS! The model fitting takes several hours to complete! If willing to reduce 
# the running time, reduce the number of chains and/or iterations below, but 
# beware of possible divergence problems! To ensure the reliability of results 
# always make sure the model fitted does not have convergence problems 
# (including free of warnings)

# OBS! If willing to improve model, please consider interaction effects, or
# modify spline fit and use cross-validation to compare models

# Parameters for the MCMC
nchains <- 4
niter <- 8000
nwarmup <- 4000

# Record code implemenation time
start_time <- Sys.time()

# Fit the model
model_1to15 <- brm(
  bf(
    Euroa ~
      Päämatkakohde * Neljännes +
      Päämatkakohde +
      Asuinalue +
      s(Yöpymiset, bs = "tp") +
      Majoitus +
      Kulkuväline +
      Matkan_tarkoitus +
      Neljännes +
      Sukupuoli +
      Ikäryhmä +
      Luontomatkailu +
      Kulttuurimatkailu +
      Kaupunkimatkailu +
      Osallistui_tapahtumiin +
      Ostosmatkailu +
      Yli_50km_matkoja_Suomessa +
      Ensi_varaus_kk_ennen +
      Matkaseura +
      Vierailut_muissa_kohteissa +
      MuutMaat +
      Urheilumatkailu +
      Hyvinvointimatkailu +
      Kiertomatkailu
  ),
  family = Gamma(link = "log"),
  data = data_1to15,
  iter = niter,
  warmup = nwarmup,
  chains = nchains,
  prior =
    c(
      set_prior("exponential(0.5)", class = "sds"),
      set_prior("normal(0, 0.5)", class = "b"),
      set_prior("normal(0, 2)", class = "Intercept")
    ),
  control = list(adapt_delta = 0.99)
)

stop_time <- Sys.time()

# Time of the code implementation
print(stop_time - start_time)

# Summary of the model fit
summary(model_1to15)

# Posterio predictive checks
pp_check(model_1to15) + xlim(c(0, 2000))


#-------------------------------------------------------------------------------
# Save the model
#-------------------------------------------------------------------------------
save(model_1to15, file = "model_1to15.RData")
