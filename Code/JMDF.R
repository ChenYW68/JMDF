rm(list=ls())
library(INLA)
library(Hmisc)
library(INLAspacetime)
library(dplyr)
library(purrr)
library(readr)
library(stringr)
library(readxl)
library(data.table)
load("./data/Model/all.inluenza.cohort.RData")
inla_df <- all.inluenza.cohort %>%
  filter(strain_type != "Yamagata"
         , season_start >= 2016
         # , study == "UGA"
  )


inla_df$age <- inla.group(inla_df$age, n = 100)
inla_df$bmi <- inla.group(inla_df$bmi, n = 100)

inla_df <- inla_df %>%
  mutate(
    x_lag1_ind = as.numeric(inla_df$x_lag1!=0),
    x_lag2_ind = as.numeric(inla_df$x_lag2!=0),
    x_lag3_ind = as.numeric(inla_df$x_lag3!=0),
    x_lag4_ind = as.numeric(inla_df$x_lag4!=0),
    x_lag5_ind = as.numeric(inla_df$x_lag5!=0)
  )


inla_df$group <- ifelse((inla_df$x_lag1_ind == 0)&(inla_df$x_lag2_ind == 0)&(inla_df$x_lag3_ind == 0), 0,
                        ifelse((inla_df$x_lag1_ind == 1)&(inla_df$x_lag2_ind == 0)&(inla_df$x_lag3_ind == 0), 1,
                               ifelse((inla_df$x_lag1_ind == 0)&(inla_df$x_lag2_ind == 1)&(inla_df$x_lag3_ind == 0), 2,
                                      ifelse((inla_df$x_lag1_ind == 0)&(inla_df$x_lag2_ind == 0)&(inla_df$x_lag3_ind == 1), 3,
                                             ifelse((inla_df$x_lag1_ind == 1)&(inla_df$x_lag2_ind == 1)&(inla_df$x_lag3_ind == 0), 4,
                                                    ifelse((inla_df$x_lag1_ind == 1)&(inla_df$x_lag2_ind == 0)&(inla_df$x_lag3_ind == 1), 5,
                                                           ifelse((inla_df$x_lag1_ind == 0)&(inla_df$x_lag2_ind == 1)&(inla_df$x_lag3_ind == 1), 6,
                                                                  7)))))))


inla_df$y_by_x_lag1 <- ifelse(inla_df$x_lag1 == 0, 0, (inla_df$y_lag1-inla_df$x_lag1)/inla_df$x_lag1)#/inla_df$x_lag1
inla_df$y_by_x_lag2 <- ifelse(inla_df$x_lag2 == 0, 0, (inla_df$y_lag2-inla_df$x_lag2)/inla_df$x_lag2)#/inla_df$x_lag2
inla_df$y_by_x_lag3 <- ifelse(inla_df$x_lag3 == 0, 0, (inla_df$y_lag3-inla_df$x_lag3)/inla_df$x_lag3)#/inla_df$x_lag3


# Build 2D mesh over (age, X)
ori.coords.0 <- data.frame(age = inla_df$age, z = inla_df$x_current)
coords.0 <- cbind(scale(ori.coords.0[, 1]), scale(ori.coords.0[, 2]))
mesh.0 <- inla.mesh.2d(loc = coords.0, max.edge = c(.1, 0.4), cutoff = .10)
mesh.0$n



ori.coords.1 <- data.frame(age = inla_df[inla_df$x_lag1_ind!=0, ]$age,
                           z = inla_df[inla_df$x_lag1_ind!=0, ]$x_lag1)
coords.1 <- cbind(scale(ori.coords.1[, 1]), scale(ori.coords.1[, 2]))
mesh.1 <- inla.mesh.2d(loc = coords.1, max.edge = c(.1, .4), cutoff = .10)
mesh.1$n



ori.coords.2 <- data.frame(age = inla_df[inla_df$x_lag2_ind!=0, ]$age,
                           z = inla_df[inla_df$x_lag2_ind!=0, ]$x_lag2)
coords.2 <- cbind(scale(ori.coords.2[, 1]), scale(ori.coords.2[, 2]))
mesh.2 <- inla.mesh.2d(loc = coords.2, max.edge = c(.1, .4), cutoff = .10)
mesh.2$n



ori.coords.3 <- data.frame(age = inla_df[inla_df$x_lag3_ind!=0, ]$age, 
                           z = inla_df[inla_df$x_lag3_ind!=0, ]$x_lag3)
coords.3 <- cbind(scale(ori.coords.3[, 1]), scale(ori.coords.3[, 2]))
mesh.3 <- inla.mesh.2d(loc = coords.3, max.edge = c(.1, .4), cutoff = .10)
mesh.3$n

# Define SPDE model
spde.0 <- inla.spde2.pcmatern(mesh  = mesh.0,
                              alpha = 2,
                              prior.range = c(3, 0.5),
                              prior.sigma = c(5, 0.5))
spde.1 <- inla.spde2.pcmatern(mesh  = mesh.1,
                              alpha = 2,
                              prior.range = c(3, 0.5),
                              prior.sigma = c(5, 0.5))
spde.2 <- inla.spde2.pcmatern(mesh  = mesh.2,
                              alpha = 2,
                              prior.range = c(3, 0.5),
                              prior.sigma = c(5, 0.5))

spde.3 <- inla.spde2.pcmatern(mesh  = mesh.3,
                              alpha = 2,
                              prior.range = c(3, 0.5),
                              prior.sigma = c(5, 0.5))


A_constr.0 <- Matrix::Matrix(1, nrow = 1, ncol = spde.0$n.spde, sparse = TRUE)
A_constr.1 <- Matrix::Matrix(1, nrow = 1, ncol = spde.1$n.spde, sparse = TRUE)
A_constr.2 <- Matrix::Matrix(1, nrow = 1, ncol = spde.2$n.spde, sparse = TRUE)
A_constr.3 <- Matrix::Matrix(1, nrow = 1, ncol = spde.3$n.spde, sparse = TRUE)


A_lag0 <- inla.spde.make.A(mesh.0, loc = coords.0)



A      <- inla.spde.make.A(mesh.1, loc = coords.1)
A_lag1 <- matrix(0, nrow = nrow(inla_df), ncol = mesh.1$n)
A_lag1[which(inla_df$x_lag1_ind == 1), ] <- as.matrix(A)
A_lag1 <- Matrix(A_lag1, sparse = TRUE)

A      <- inla.spde.make.A(mesh.2, loc = coords.2)
A_lag2 <- matrix(0, nrow = nrow(inla_df), ncol = mesh.2$n)
A_lag2[which(inla_df$x_lag2_ind == 1), ] <- as.matrix(A)
A_lag2 <- Matrix(A_lag2, sparse = TRUE)

A      <- inla.spde.make.A(mesh.3, loc = coords.3)
A_lag3 <- matrix(0, nrow = nrow(inla_df), ncol = mesh.3$n)
A_lag3[which(inla_df$x_lag3_ind == 1), ] <- as.matrix(A)
A_lag3 <- Matrix(A_lag3, sparse = TRUE)

K      <- 100
method <- "JMDF-Ensemble"
Pred.summary   <- Pred.detail <- NULL

H1N1     <- inla_df[inla_df$strain_type == "H1N1", ]
H3N2     <- inla_df[inla_df$strain_type == "H3N2", ]
Victoria <- inla_df[inla_df$strain_type == "Victoria", ]

for (k in 1:K) {
  set.seed(k)
  inla_df$posttiter <- inla_df$true.posttiter
  n <- nrow(H1N1)
  train_index       <- sort(sample(1:n, ceiling(0.8*n), replace = F))
  test_index        <- sort((1:n)[((1:n)%nin% train_index)])
  test_index.1 <- c(test_index, n + test_index, 2*n + test_index)
  inla_df$posttiter[test_index.1] <-  NA
  stk <- inla.stack(
                    data = list(y = inla_df$posttiter),
                    A = list(
                      A_lag0,  
                      A_lag1,    
                      A_lag2,   
                      A_lag3,  
                      1,           
                      1,
                      1,
                      1,
                      1,
                      1,
                      1,
                      1,
                      1,
                      1,
                      1,
                      1,
                      1,
                      1,
                      1
                    ),
                    effects  = list(
                      s_lag0 = 1:mesh.0$n,   
                      s_lag1 = 1:mesh.1$n,    
                      s_lag2 = 1:mesh.2$n,   
                      s_lag3 = 1:mesh.3$n, 
                      intercept = rep(1, nrow(inla_df)),
                      age       = inla_df$age,
                      age.group = inla_df$age.group,
                      bmi.group = inla_df$bmi.group,
                      bmi       = inla_df$bmi,
                      group     = inla_df$group,
                      subject   = inla_df$subject_id,
                      y_by_x_lag1  = inla_df$y_by_x_lag1,
                      y_by_x_lag2  = inla_df$y_by_x_lag2,
                      y_by_x_lag3  = inla_df$y_by_x_lag3,
                      x_current    = inla_df$x_current,
                      x_lag1       = inla_df$x_lag1,
                      x_lag2       = inla_df$x_lag2,
                      x_lag3       = inla_df$x_lag3,
                      strain       = inla_df$strain_type
                    ),
                    tag = "model"
                  )
  
  formula <- y ~ -1 + intercept +
            y_by_x_lag1 + 
            y_by_x_lag2 +  
            y_by_x_lag3 +
            # f(age,
            #   model  = 'rw2',
            #   constr = TRUE,
            #   hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) +
            f(bmi, 
              model  = 'rw2', 
              constr = TRUE,
              hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) +
            f(s_lag0, model = spde.0, extraconstr = list(A = A_constr.0, e = 0)) +  
            f(s_lag1, model = spde.1, extraconstr = list(A = A_constr.1, e = 0)) +
            f(s_lag2, model = spde.2, extraconstr = list(A = A_constr.2, e = 0)) +
            f(s_lag3, model = spde.3, extraconstr = list(A = A_constr.3, e = 0)) +
            f(age.group, 
              model  = "iid", 
              constr = TRUE, 
              hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) + 
            # f(bmi.group, model = "iid", constr = TRUE, hyper = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) + 
            # f(group, model = "iid", constr = TRUE, hyper = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) + 
            f(subject, 
              model  = "iid", 
              constr = TRUE, 
              hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) +
            f(strain, 
              model  = "iid", 
              constr = TRUE, 
              hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) 
  
  JMDF_GMRF_3 <- inla(
                  formula,
                  data              = inla.stack.data(stk),
                  control.predictor = list(A = inla.stack.A(stk), link = 1),
                  family         = "gaussian",
                  control.family = lapply(1:1, function(x)
                    list(hyper = list(prec = list(prior = "pc.prec", param = c(3, 0.01))))),
                  num.threads     = 10,  # Use 5 threads for this model
                  verbose         = FALSE,   # Monitor progress
                  control.compute = list(cpo = F)
                )
  
  # 3
  formula <- y ~ -1 + intercept +
    y_by_x_lag1 + 
    y_by_x_lag2 +  
    # y_by_x_lag3 +
    # f(age,
    #   model  = 'rw2',
    #   constr = TRUE,
    #   hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) +
    f(bmi, 
      model  = 'rw2', 
      constr = TRUE,
      hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) +
    f(s_lag0, model = spde.0, extraconstr = list(A = A_constr.0, e = 0)) +  
    f(s_lag1, model = spde.1, extraconstr = list(A = A_constr.1, e = 0)) +
    f(s_lag2, model = spde.2, extraconstr = list(A = A_constr.2, e = 0)) +
    # f(s_lag3, model = spde.3, extraconstr = list(A = A_constr.3, e = 0)) +
    f(age.group, 
      model  = "iid", 
      constr = TRUE, 
      hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) + 
    f(subject, 
      model  = "iid", 
      constr = TRUE, 
      hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) +
    f(strain, 
      model  = "iid", 
      constr = TRUE, 
      hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01))))
  
  JMDF_GMRF_2 <- inla(
                  formula,
                  data              = inla.stack.data(stk),
                  control.predictor = list(A = inla.stack.A(stk), link = 1),
                  family         = "gaussian",
                  control.family = lapply(1:1, function(x)
                    list(hyper = list(prec = list(prior = "pc.prec", param = c(3, 0.01))))),
                  num.threads     = 10,  # Use 5 threads for this model
                  verbose         = FALSE,   # Monitor progress
                  control.compute = list(cpo = F)
                )
  
  formula <- y ~ -1 + intercept +
            y_by_x_lag1 + 
            f(bmi, 
              model  = 'rw2', 
              constr = TRUE,
              hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) +
            f(s_lag0, model = spde.0, extraconstr = list(A = A_constr.0, e = 0)) +  
            f(s_lag1, model = spde.1, extraconstr = list(A = A_constr.1, e = 0)) +
            f(age.group, 
              model  = "iid", 
              constr = TRUE, 
              hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) + 
            f(subject, 
              model  = "iid", 
              constr = TRUE, 
              hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) +
            f(strain, 
              model  = "iid", 
              constr = TRUE, 
              hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) 
  
  JMDF_GMRF_1 <- inla(
                    formula,
                    data              = inla.stack.data(stk),
                    control.predictor = list(A = inla.stack.A(stk), link = 1),
                    family         = "gaussian",
                    control.family = lapply(1:1, function(x)
                      list(hyper = list(prec = list(prior = "pc.prec", param = c(3, 0.01))))),
                    num.threads     = 10,  # Use 5 threads for this model
                    verbose         = FALSE,   # Monitor progress
                    control.compute = list(cpo = F)
                  )
  
  
  formula <- y ~ -1 + intercept +
              f(bmi, 
                model  = 'rw2', 
                constr = TRUE,
                hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) +
              f(s_lag0, model = spde.0, extraconstr = list(A = A_constr.0, e = 0)) +  
              f(age.group, 
                model  = "iid", 
                constr = TRUE, 
                hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) + 
              f(subject, 
                model  = "iid", 
                constr = TRUE, 
                  hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) +
              f(strain, 
                model  = "iid", 
                constr = TRUE, 
                hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01))))
  
  JMDF_GMRF_0 <- inla(
                    formula,
                    data              = inla.stack.data(stk),
                    control.predictor = list(A = inla.stack.A(stk), link = 1),
                    family         = "gaussian",
                    control.family = lapply(1:1, function(x)
                      list(hyper = list(prec = list(prior = "pc.prec", param = c(3, 0.01))))),
                    num.threads     = 10,  # Use 5 threads for this model
                    verbose         = FALSE,   # Monitor progress
                    control.compute = list(cpo = F)
                  )
  
  
  #JMDF-LR
  formula <- y ~ -1 + intercept +
            x_current +
            # y_by_x_lag2 +  
            # y_by_x_lag3 +
            f(age,
              model  = 'rw2',
              constr = TRUE,
              hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) +
            f(bmi, 
              model  = 'rw2', 
              constr = TRUE,
              hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) +
            f(age.group, 
              model  = "iid", 
              constr = TRUE, 
              hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) + 
            f(subject, 
              model  = "iid", 
              constr = TRUE, 
              hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) +
            f(strain, 
              model  = "iid", 
              constr = TRUE, 
              hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01))))
  
  JMDF_LR_0 <- inla(
              formula,
              data              = inla.stack.data(stk),
              control.predictor = list(A = inla.stack.A(stk), link = 1),
              family         = "gaussian",
              control.family = lapply(1:1, function(x)
                list(hyper = list(prec = list(prior = "pc.prec", param = c(3, 0.01))))),
              num.threads     = 10,  # Use 5 threads for this model
              verbose         = FALSE,   # Monitor progress
              control.compute = list(cpo = F)
            )
  
  formula <- y ~ -1 + intercept +
              x_current +
              x_lag1    +
              y_by_x_lag1 + 
              # y_by_x_lag2 +  
              # y_by_x_lag3 +
              f(age,
                model  = 'rw2',
                constr = TRUE,
                hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) +
              f(bmi, 
                model  = 'rw2', 
                constr = TRUE,
                hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) +
              f(age.group, 
                model  = "iid", 
                constr = TRUE, 
                hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) + 
              f(subject, 
                model  = "iid", 
                constr = TRUE, 
                hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) +
              f(strain, 
                model  = "iid", 
                constr = TRUE, 
                hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01))))
  
  JMDF_LR_1 <- inla(
                formula,
                data              = inla.stack.data(stk),
                control.predictor = list(A = inla.stack.A(stk), link = 1),
                family         = "gaussian",
                control.family = lapply(1:1, function(x)
                  list(hyper = list(prec = list(prior = "pc.prec", param = c(3, 0.01))))),
                num.threads     = 10,  # Use 5 threads for this model
                verbose         = FALSE,   # Monitor progress
                control.compute = list(cpo = F)
              )
  
  formula <- y ~ -1 + intercept +
              x_current +
              x_lag1 +
              x_lag2 +
              y_by_x_lag1 + 
              y_by_x_lag2 +  
              # y_by_x_lag3 +
              f(age,
                model  = 'rw2',
                constr = TRUE,
                hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) +
              f(bmi, 
                model  = 'rw2', 
                constr = TRUE,
                hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) +
              f(age.group, 
                model  = "iid", 
                constr = TRUE, 
                hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) + 
              f(subject, 
                model  = "iid", 
                constr = TRUE, 
                hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) +
              f(strain, 
                model  = "iid", 
                constr = TRUE, 
                hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01))))
  
  JMDF_LR_2 <- inla(
              formula,
              data              = inla.stack.data(stk),
              control.predictor = list(A = inla.stack.A(stk), link = 1),
              family         = "gaussian",
              control.family = lapply(1:1, function(x)
                list(hyper = list(prec = list(prior = "pc.prec", param = c(3, 0.01))))),
              num.threads     = 10,  # Use 5 threads for this model
              verbose         = FALSE,   # Monitor progress
              control.compute = list(cpo = F)
            )
  
  formula <- y ~ -1 + intercept +
            x_current +
            x_lag1 +
            x_lag2 +
            x_lag3 +
            y_by_x_lag1 + 
            y_by_x_lag2 +  
            y_by_x_lag3 +
            f(age,
              model  = 'rw2',
              constr = TRUE,
              hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) +
            f(bmi, 
              model  = 'rw2', 
              constr = TRUE,
              hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) +
            f(age.group, 
              model  = "iid", 
              constr = TRUE, 
              hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) + 
            f(subject, 
              model  = "iid", 
              constr = TRUE, 
              hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01)))) +
            f(strain, 
              model  = "iid", 
              constr = TRUE, 
              hyper  = list(prec = list(prior = "pc.prec", param = c(1, 0.01))))
  
  JMDF_LR_3 <- inla(
                formula,
                data              = inla.stack.data(stk),
                control.predictor = list(A = inla.stack.A(stk), link = 1),
                family         = "gaussian",
                control.family = lapply(1:1, function(x)
                  list(hyper = list(prec = list(prior = "pc.prec", param = c(3, 0.01))))),
                num.threads     = 10,  # Use 5 threads for this model
                verbose         = FALSE,   # Monitor progress
                control.compute = list(cpo = F)
              )
  
  logmls <- c(JMDF_GMRF_3$mlik[1,1], JMDF_GMRF_2$mlik[1,1], JMDF_GMRF_1$mlik[1,1], JMDF_GMRF_0$mlik[1,1],
              JMDF_LR_3$mlik[1,1], JMDF_LR_2$mlik[1,1], JMDF_LR_1$mlik[1,1], JMDF_LR_0$mlik[1,1])
  
  weights <- exp(1e-2 * (logmls - max(logmls)))  # stabilize numerically
  logmls.weights <- weights / sum(weights)
  logmls.weights
  
  
  #ensemble summary//test_index.1
  ensemble.fun <- function(data, model, liklihood, w, test.ind, k = 1, method = ""){
    cov.ind <- which(colnames(data) %in% c("strain_type", "is_man", "age.group","bmi.group", "true.posttiter"))
    temp    <- data.frame(method = method,
                         iter   = k,
                         data[test.ind, c(1, cov.ind)],
                         pred      = model$summary.fitted.values[["mean"]][test.ind],
                         liklihood = liklihood,
                         w         = w)
    return(temp)
  }
  da <- ensemble.fun(data = inla_df, model = JMDF_GMRF_3, liklihood = JMDF_GMRF_3$mlik[1,1], 
                     w = logmls.weights[1], test.ind = test_index.1, k = k, method =  "JMDF-GMRF_3")
  # indx <- which(colnames(da) %in% c("method", "subject_id", " "))
    
    
  temp.detail <- rbind(ensemble.fun(data = inla_df, model = JMDF_GMRF_3, liklihood = JMDF_GMRF_3$mlik[1,1], 
                                    w = logmls.weights[1], test.ind = test_index.1, k = k, method =  "JMDF-GMRF_3"), 
                       ensemble.fun(data = inla_df, model = JMDF_GMRF_2, liklihood = JMDF_GMRF_2$mlik[1,1], 
                                    w = logmls.weights[2], test.ind = test_index.1, k = k, method =  "JMDF-GMRF_2"), 
                       ensemble.fun(data = inla_df, model = JMDF_GMRF_1, liklihood = JMDF_GMRF_1$mlik[1,1], 
                                    w = logmls.weights[3], test.ind = test_index.1, k = k, method =  "JMDF-GMRF_1"), 
                       ensemble.fun(data = inla_df, model = JMDF_GMRF_0, liklihood = JMDF_GMRF_0$mlik[1,1], 
                                    w = logmls.weights[4], test.ind = test_index.1, k = k, method =  "JMDF-GMRF_0"), 
                       ensemble.fun(data = inla_df, model = JMDF_LR_3, liklihood = JMDF_LR_3$mlik[1,1], 
                                    w = logmls.weights[5], test.ind = test_index.1, k = k, method =  "JMDF-LR_3"), 
                       ensemble.fun(data = inla_df, model = JMDF_LR_2, liklihood = JMDF_LR_2$mlik[1,1], 
                                    w = logmls.weights[6], test.ind = test_index.1, k = k, method =  "JMDF-LR_2"), 
                       ensemble.fun(data = inla_df, model = JMDF_LR_1, liklihood = JMDF_LR_1$mlik[1,1], 
                                    w = logmls.weights[7], test.ind = test_index.1, k = k, method =  "JMDF-LR_1"), 
                       ensemble.fun(data = inla_df, model = JMDF_LR_0, liklihood = JMDF_LR_0$mlik[1,1], 
                                    w = logmls.weights[8], test.ind = test_index.1, k = k, method =  "JMDF-LR_0")
                       
              )
  
  
  
  
  test_preds.1 <- logmls.weights[1]*(JMDF_GMRF_3$summary.fitted.values[,"mean"][test_index]) +
    logmls.weights[2]*(JMDF_GMRF_2$summary.fitted.values[,"mean"][test_index])+
    logmls.weights[3]*(JMDF_GMRF_1$summary.fitted.values[,"mean"][test_index])+
    logmls.weights[4]*(JMDF_GMRF_0$summary.fitted.values[,"mean"][test_index])+
    logmls.weights[5]*(JMDF_LR_3$summary.fitted.values[,"mean"][test_index])+
    logmls.weights[6]*(JMDF_LR_2$summary.fitted.values[,"mean"][test_index])+
    logmls.weights[7]*(JMDF_LR_1$summary.fitted.values[,"mean"][test_index])+
    logmls.weights[8]*(JMDF_LR_0$summary.fitted.values[,"mean"][test_index])
  
  test_preds.2 <- logmls.weights[1]*(JMDF_GMRF_3$summary.fitted.values[,"mean"][n + test_index]) +
    logmls.weights[2]*(JMDF_GMRF_2$summary.fitted.values[,"mean"][n + test_index])+
    logmls.weights[3]*(JMDF_GMRF_1$summary.fitted.values[,"mean"][n + test_index])+
    logmls.weights[4]*(JMDF_GMRF_0$summary.fitted.values[,"mean"][n + test_index])+
    logmls.weights[5]*(JMDF_LR_3$summary.fitted.values[,"mean"][n + test_index])+
    logmls.weights[6]*(JMDF_LR_2$summary.fitted.values[,"mean"][n + test_index])+
    logmls.weights[7]*(JMDF_LR_1$summary.fitted.values[,"mean"][n + test_index])+
    logmls.weights[8]*(JMDF_LR_0$summary.fitted.values[,"mean"][n + test_index])
  
  test_preds.3 <- logmls.weights[1]*(JMDF_GMRF_3$summary.fitted.values[,"mean"][2*n + test_index]) +
    logmls.weights[2]*(JMDF_GMRF_2$summary.fitted.values[,"mean"][2*n + test_index])+
    logmls.weights[3]*(JMDF_GMRF_1$summary.fitted.values[,"mean"][2*n + test_index])+
    logmls.weights[4]*(JMDF_GMRF_0$summary.fitted.values[,"mean"][2*n + test_index])+
    logmls.weights[5]*(JMDF_LR_3$summary.fitted.values[,"mean"][2*n + test_index])+
    logmls.weights[6]*(JMDF_LR_2$summary.fitted.values[,"mean"][2*n + test_index])+
    logmls.weights[7]*(JMDF_LR_1$summary.fitted.values[,"mean"][2*n + test_index])+
    logmls.weights[8]*(JMDF_LR_0$summary.fitted.values[,"mean"][2*n + test_index])
  
  
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
  
  
  if(k>2){
    load(paste0("./result/Pred_", method, "_II.RData"))
  }
  Pred.summary <- rbind(Pred.summary, rbind(Pred.1, Pred.2, Pred.3))
  Pred.detail <- rbind(Pred.detail, temp.detail)
  save(Pred.summary, Pred.detail, file =  paste0("./result/Pred_", method, "_II.RData"))
  
  
  
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



