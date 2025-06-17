# Joint Modeling and Dynamic Forecasting of Influenza Vaccine Response for Incomplete Longitudinal Data

This Github page provides code and data for reproducing the results in the manuscript: Joint Modeling and Dynamic Forecasting of Influenza Vaccine Response for Incomplete Longitudinal Data.

## Summary
Influenza vaccines are essential for protecting against infection and disease, but a major challenge lies in the wide variability of vaccine-induced immune responses across individuals. Predictive modeling offers a promising avenue for addressing this issue by enabling policymakers to prioritize vaccine types and allocate resources efficiently to high-risk populations ahead of peak infection periods. However, such modeling faces significant challenges, including incomplete longitudinal vaccine measurements, complex dynamic interactions between host-related factors and measurements, and the need to account for multi-strain vaccine responses within the same individual. This study introduces a novel joint modeling and dynamic forecasting (JMDF) approach using Gaussian Markov random fields (GMRF) to predict vaccine responses to address these three methodological challenges and improve vaccine response prediction: (1) adaptive use of longitudinal measurements as covariates without requiring imputation, thereby avoiding the inherent uncertainties of missing data imputation; (2) the new application of Gaussian Markov random fields (GMRFs) to capture intricate interactions host-related factors and both pre- and post-vaccination measurements; and (3) joint forecasting of responses to multi-strain. This work advances statistical methods for vaccine response forecasting and offers valuable tools to inform and personalize future vaccination strategies.


## 
<figure id="Figure1">
    <p align="center">
  <img src="./figure/simFig1.jpg" width=80% height=80%>
  </p>
  <figcaption>
  <strong>Figure 1:</strong> Estimated smoothing functions using different numbers of knots in the RW2 approximation when $N = 1{,}000$.
  </figcaption>
</figure>
