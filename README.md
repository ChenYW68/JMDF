# Joint Modeling and Dynamic Forecasting of Influenza Vaccine Response for Incomplete Longitudinal Data

This Github page provides code for reproducing the results in the manuscript: Joint Modeling and Dynamic Forecasting of Influenza Vaccine Response for Incomplete Longitudinal Data.

## Summary
Influenza vaccines are essential for protecting against infection and disease, but a major challenge lies in the wide variability of vaccine-induced immune responses across individuals. Predictive modeling offers a promising avenue for addressing this issue by enabling policymakers to prioritize vaccine types and allocate resources efficiently to high-risk populations ahead of peak infection periods. However, such modeling faces significant challenges, including incomplete longitudinal vaccine measurements, complex dynamic interactions between host-related factors and measurements, and the need to account for multi-strain vaccine responses within the same individual. This study introduces a novel joint modeling and dynamic forecasting (JMDF) approach using Gaussian Markov random fields (GMRF) to predict vaccine responses to address these three methodological challenges and improve vaccine response prediction: (1) adaptive use of longitudinal measurements as covariates without requiring imputation, thereby avoiding the inherent uncertainties of missing data imputation; (2) the new application of Gaussian Markov random fields (GMRFs) to capture intricate interactions host-related factors and both pre- and post-vaccination measurements; and (3) joint forecasting of responses to multi-strain. This work advances statistical methods for vaccine response forecasting and offers valuable tools to inform and personalize future vaccination strategies.


## Simulations
<figure id="Figure1">
    <p align="center">
  <img src="./figure/simFig1.jpg" width=80% height=80%>
  </p>
  <figcaption>
  <strong>Figure 1:</strong> Estimated smoothing functions using different numbers of knots in the RW2 approximation when N = 1,500.
  </figcaption>
</figure>

<figure id="Figure2">
    <p align="center">
  <img src="./figure/simFig2.jpg" width=60% height=80%>
  </p>
  <figcaption>
  <strong>Figure 2:</strong> Maps of the random processes $G_{0}, G_{1}, G_{2},$ and $G_{3}$ from top to bottom. Left panels show the simulated Gaussian Markov random fields, and right panels show the corresponding recovered fields. The first row ($G_{0}$) is recovered based on a full sample size of N = 1500, while the remaining rows correspond to $G_{m}$ for m = 1, 2, 3, with available sample sizes of N = 964, 595, and 351, respectively, reflecting missingness patterns derived from the UGA cohort.
  </figcaption>
</figure>

## Real data analysis using the UGA cohort
The following maps characterize the interaction effects between age and historical longitudinal pre-vaccination HAI titers on future vaccination responses.
<figure id="Figure3">
  <table align="center">
    <tr>
      <td><img src="./figure/Fig2_1.jpg" width="500px"></td>
      <td><img src="./figure/Fig2_2.jpg" width="500px"></td>
    </tr>
    <tr>
      <td><img src="./figure/Fig2_3.jpg" width="500px"></td>
      <td><img src="./figure/Fig2_4.jpg" width="500px"></td>
    </tr>
  </table>
  <figcaption align="center">
    <strong>Figure 3:</strong> Recovered Gaussian Markov random fields between age and longitudinal pre-vaccination HAI titers.
  </figcaption>
</figure>
