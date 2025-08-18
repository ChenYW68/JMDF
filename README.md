# Joint Modeling and Dynamic Ensemble Forecasting of Influenza Vaccine Responses from Complex Longitudinal Trajectories

This Github page provides code for reproducing the results in the manuscript: Joint Modeling and Dynamic Ensemble Forecasting of Influenza Vaccine Responses from Incomplete Longitudinal Data.

## Real-world implications
The forecasts and simulations using advance statistics models can enhance our understanding of vaccine-induced immunity, aligning well with the goals of the [Computational Models of Immunity to Pertussis Booster Vaccinations (CMI-PB) Project](https://www.cmi-pb.org/blog/prediction-challenge-overview/).
## Summary
Longitudinal measurement trajectories have become increasingly valuable for deepening our predictive understanding of vaccine-induced immunity. However, the complexity of immune interaction patterns inherent in these trajectories, along with their incompleteness and high heterogeneity, introduces significant methodological challenges for predictive modeling.
To address these challenges, we introduce the Joint Modeling and Dynamic Forecasting (JMDF) framework to enhance vaccine response prediction. JMDF provides four key advances: (1) adaptive use of non-missing longitudinal measurements as covariates without requiring imputation; (2) a novel application of Gaussian Markov random fields (GMRFs) to capture longitudinal interactions between demographic factors and vaccination-related measurements; (3) joint forecasting of responses to multiple vaccine subtypes while allowing them to share structured dependence; and (4) an efficient ensemble forecasting strategy that integrates sub-JMDF models. This work advances modern statistical modeling in public health, particularly in the area of vaccine response prediction and immune response simulation, with the potential to support personalized vaccination strategies.

## Data from the human influenza vaccine cohort study
To understand vaccine-induced immunity, an ongoing human influenza vaccine cohort study is being conducted. The cohort was initiated in 2013 at two sites: one in Florida (FL) and the other in Pennsylvania (PA). Since 2016, the study has been primarily conducted at the [University of Georgia (UGA) in Athens, Georgia, United States](https://cider.uga.edu/about-cider).

## Simulations
<!-- The estimates of the nonlinear function closely match the true function and remain remarkably robust across several different choices of the number of knots used in the RW2 approximation, as shown in <a href="#Figure3">Figure 1</a>. 
<figure id="Figure1">
  <table align="center">
    <tr>
      <td><img src="./figure/simFig1.jpg" width="800px"></td>
    </tr>
  </table>
  <figcaption align="center">
    <strong>Figure 1:</strong> Estimated smoothing functions using different numbers of knots in the RW2 approximation when N = 1,500.
  </figcaption>
</figure>
-->

<br><br>
By comparing the four recovered maps (right panels of <a href="#Figure1">Figure 1</a>) with the corresponding true GPs (left panels), the JMDF model accurately identifies each of the latent processes.
<figure id="Figure1">
    <p align="center">
  <img src="./figure/simFig2.jpg" width="600px">
  </p>
  <figcaption>
 <strong>Figure 1:</strong> Maps of the random processes G<sub>0</sub>, G<sub>1</sub>, G<sub>2</sub>, and G<sub>3</sub> from top to bottom. Left panels show the simulated Gaussian Markov random fields, and right panels show the corresponding recovered fields. The first row (G<sub>0</sub>) is recovered based on a full sample size of N = 1500, while the remaining rows correspond to G<sub>m</sub> for m = 1, 2, 3, with available sample sizes of N = 964, 595, and 351, respectively, reflecting missingness patterns derived from the UGA cohort.
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
    <strong>Figure 2:</strong> Recovered Gaussian Markov random fields between human age and longitudinal pre-vaccination HAI titers.
  </figcaption>
</figure>
