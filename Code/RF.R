# Load the H2O library
# library(h2o)
library(Hmisc)
library(randomForest)
# Initialize the H2O cluster
# h2o.init()
load("./data/Model/all.inluenza.cohort.RData")
inla_df <- all.inluenza.cohort %>%
  filter(strain_type != "Yamagata"
         , season_start >= 2016
         # , study == "UGA"
  )


inla_df$true.posttiter <- inla_df$posttiter


K <- 100 #"age","weight_kg", "height_cm"
vari.index <- which(colnames(inla_df) %in% c("posttiter",
                                             "x_current",
                                             "age",
                                             "bmi"#,
                                             # "x_lag1", 
                                             # "x_lag2",
                                             # "x_lag3",
                                             # "y_by_x_lag1", 
                                             # "y_by_x_lag2",
                                             # "y_by_x_lag3"
                                             ))#"weight_kg", "height_cm"


Pred   <- NULL
method <- "RF"
for (k in 1:K) {
  set.seed(k)
  inla_df$posttiter <- inla_df$true.posttiter
  n                 <- nrow(H1N1)
  train_index       <- sort(sample(1:n, ceiling(0.8*n), replace = F))
  test_index        <- sort((1:n)[((1:n)%nin% train_index)])
  test_index.1      <- c(test_index, n + test_index, 2*n + test_index)
  
 
  train_data  <- inla_df[-test_index.1, vari.index] 
  
  H1N1.test_data   <- inla_df[test_index, vari.index] 
  H3N2.test_data   <- inla_df[n + test_index, vari.index] 
  Victoria.test_data   <- inla_df[2*n + test_index, vari.index] 
  
  
  rf_model <- randomForest(posttiter ~.
                           , ntree = 1000
                           , proximity = TRUE,
                           , data = train_data)
 
  test_preds.1 <- as.vector(predict(rf_model, H1N1.test_data))
  test_preds.2 <- as.vector(predict(rf_model, H3N2.test_data))
  test_preds.3 <- as.vector(predict(rf_model, Victoria.test_data))
  
  cov.ind <- which(colnames(inla_df) %in% c("is_man", "age.group","bmi.group", "true.posttiter"))
  
  Pred.1 <- data.frame(method = method, 
                       fold = k, 
                       H1N1[test_index, c(1, cov.ind)], 
                       pred = test_preds.1,
                       group = "H1N1")
  
  Pred.2 <- data.frame(method = method, 
                       fold = k, 
                       H3N2[test_index, c(1, cov.ind)], 
                       pred = test_preds.2,
                       group = "H3N2")
  
  Pred.3 <- data.frame(method = method, 
                       fold = k, 
                       Victoria[test_index, c(1, cov.ind)], 
                       pred = test_preds.3,
                       group = "Victoria")
  
  Pred <- rbind(Pred, rbind(Pred.1, Pred.2, Pred.3))
  
  z <- c(H1N1$true.posttiter[test_index], 
         H3N2$true.posttiter[test_index], 
         Victoria$true.posttiter[test_index],
         Pred.1$pred, Pred.2$pred, Pred.3$pred)
  plot(c(Pred.1$pred, Pred.2$pred, Pred.3$pred),
       c(H1N1$true.posttiter[test_index], 
         H3N2$true.posttiter[test_index], 
         Victoria$true.posttiter[test_index]),
       xlim = range(z),
       ylim = range(z), 
       xla = "forecast", 
       ylab = "ture")
  abline(a= 0, b = 1)
  
}
library(HDCM)
spT_validation()



rmse_gender <- Pred %>%
  group_by(is_man) %>%
  summarise(RMSE = RMSE(true.posttiter, pred),
            MAE  = MAE(true.posttiter, pred))
rmse_age <- Pred %>%
  group_by(age.group) %>%
  summarise(RMSE = RMSE(true.posttiter, pred),
            MAE  = MAE(true.posttiter, pred))

rmse_bmi <- Pred %>%
  group_by(bmi.group) %>%
  summarise(RMSE = RMSE(true.posttiter, pred),
            MAE  = MAE(true.posttiter, pred))
rmse_group <- Pred %>%
  group_by(group) %>%
  summarise(RMSE = RMSE(true.posttiter, pred),
            MAE  = MAE(true.posttiter, pred))
Res <- data.frame(method = method, 
                  Male = rmse_gender$RMSE[2],
                  Femal = rmse_gender$RMSE[1],
                  Normal = rmse_bmi$RMSE[2],
                  Obesity = rmse_bmi$RMSE[1],
                  Younger = rmse_age$RMSE[2],
                  Older = rmse_age$RMSE[1],
                  Overall = RMSE(Pred$true.posttiter, Pred$pred),
                  H1N1 = rmse_group$RMSE[1],
                  H3N2 = rmse_group$RMSE[2],
                  Victoria = rmse_group$RMSE[3])
Res



# writexl::write_xlsx(Res, path = paste0("./result/", method, ".xlsx"))
g <- unique(Pred$group)
group.Res1 <- group.Res2 <- group.Res3 <- NULL
for(i in 1:3){
  da <- Pred[Pred$group %in% g[i], ]
  rmse_gender <- Pred[Pred$group %in% g[i], ] %>%
    group_by(is_man) %>%
    summarise(RMSE = RMSE(true.posttiter, pred),
              MAE  = MAE(true.posttiter, pred),
              CRPS  = CRPS(true.posttiter, pred))
  rmse_age <- Pred[Pred$group %in% g[i], ] %>%
    group_by(age.group) %>%
    summarise(RMSE = RMSE(true.posttiter, pred),
              MAE  = MAE(true.posttiter, pred),
              CRPS  = CRPS(true.posttiter, pred))
  
  rmse_bmi <- Pred[Pred$group %in% g[i], ] %>%
    group_by(bmi.group) %>%
    summarise(RMSE = RMSE(true.posttiter, pred),
              MAE  = MAE(true.posttiter, pred),
              CRPS  = CRPS(true.posttiter, pred))
  
  temp1 <- data.frame(Strain = g[i],
                      method = method, 
                      Male = HDCM::Round(rmse_gender$RMSE[2], 4),
                      Femal = HDCM::Round(rmse_gender$RMSE[1], 4),
                      Normal = HDCM::Round(rmse_bmi$RMSE[2], 4),
                      Obesity = HDCM::Round(rmse_bmi$RMSE[1], 4),
                      Younger = HDCM::Round(rmse_age$RMSE[2], 4),
                      Older = HDCM::Round(rmse_age$RMSE[1], 4),
                      Overall = HDCM::Round(RMSE(da$true.posttiter, da$pred), 4))
  group.Res1 <- rbind(group.Res1, temp1)
  
  temp2 <- data.frame(Strain = g[i],
                      method = method, 
                      Male = HDCM::Round(rmse_gender$MAE[2], 4),
                      Femal = HDCM::Round(rmse_gender$MAE[1], 4),
                      Normal = HDCM::Round(rmse_bmi$MAE[2], 4),
                      Obesity = HDCM::Round(rmse_bmi$MAE[1], 4),
                      Younger = HDCM::Round(rmse_age$MAE[2], 4),
                      Older = HDCM::Round(rmse_age$MAE[1], 4),
                      Overall = HDCM::Round(MAE(da$true.posttiter, da$pred), 4))
  group.Res2 <- rbind(group.Res2, temp2)
  
  
  temp3 <- data.frame(Strain = g[i],
                      method = method, 
                      Male = HDCM::Round(rmse_gender$CRPS[2], 4),
                      Femal = HDCM::Round(rmse_gender$CRPS[1], 4),
                      Normal = HDCM::Round(rmse_bmi$CRPS[2], 4),
                      Obesity = HDCM::Round(rmse_bmi$CRPS[1], 4),
                      Younger = HDCM::Round(rmse_age$CRPS[2], 4),
                      Older = HDCM::Round(rmse_age$CRPS[1], 4),
                      Overall = HDCM::Round(CRPS(da$true.posttiter, da$pred), 4))
  group.Res3 <- rbind(group.Res3, temp3)
  
}
writexl::write_xlsx(group.Res1, path = paste0("./result/rmse_group_", method, ".xlsx"))
writexl::write_xlsx(group.Res2, path = paste0("./result/mae_group_", method, ".xlsx"))
writexl::write_xlsx(group.Res3, path = paste0("./result/crps_group_", method, ".xlsx"))
group.Res1


