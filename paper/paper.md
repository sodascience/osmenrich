---
title: 'Osmenrich: An R package to enrich geocoded data'
tags:
  - R
  - geospatial data
  - goespatial
  - sf
  - openstreetmap
  - osrm
authors:
  - name: Erik-Jan van Kesteren
    orcid: 0000-0003-1548-1663
    affiliation: "1, 2"
  - name: Leonardo Jaya Vida
    orcid: 0000-0002-0461-016X
    affiliation: "1, 2"
  - name: Jonathan de Bruin
    orcid: 0000-0002-4297-0502
    affiliation: "1, 2"
affiliations:
 - name: Utrecht University
   index: 1
 - name: ODISSEI
   index: 2
date: 25 April 2021
bibliography: paper.bib
---

# Summary
Our package provides a user-friendly way to enrich geographic datasets, for example observations on a map, with geographic features around those observations. The package is builds on existing infrastructure for interfacing with OpenStreetMaps (`osmdata`, citation), and works well with the existing ecosystem of packages for (geospatial) data analysis, namely `sf` (citation) and the `tidyverse` (citation). In short, `osmenrich` streamlines and standardizes the process going from a raw dataset with observations and locations to a tidy (citation wickham tidy data), rich dataset with multiple relevant geographical features about those locations. Figure \autoref{fig:workflow} shows graphically the basic workflow of `osmenrich`.

![Basic workflow of `osmenrich`. \label{fig:workflow}](figure-01.png)

# Statement of need
Geographic data is valuable in research where the environment influences the process under investigation. For example, (green space utrecht citation), (plastic spotter), (great backyard bird count). Various software solutions exist for extracting data from geographic information systems (many citations here!). However, in order to include these data in further analysis (e.g., universal kriging in `gstat`, citation), these data often need further processing and, crucially, _aggregation_. Within this problem space, the contributions of `osmenrich` are as follows:

- Creating a user-friendly interface to OpenStreetMaps, abstracting away the necessary API calls.
- Defining standardized ways to aggregate geographic information based on kernels (see \autoref{sec:kern}).
- Allowing distance measures based on routing, such as duration by foot or distance by car (see \autoref{sec:rout}).

In this way, researchers can focus on the research questions themselves, rather than spending time figuring out how to aggregate geographic data: which features at which distance are relevant for the process under investigation?

# Kernels
\label{sec:kern}

# Routing
\label{sec:rout}

# Citations

Citations to entries in paper.bib should be in
[rMarkdown](http://rmarkdown.rstudio.com/authoring_bibliographies_and_citations.html)
format.

If you want to cite a software repository URL (e.g. something on GitHub without a preferred
citation) then you can do it with the example BibTeX entry below for @fidgit.

For a quick reference, the following citation commands can be used:
- `@author:2001`  ->  "Author et al. (2001)"
- `[@author:2001]` -> "(Author et al., 2001)"
- `[@author1:2001; @author2:2001]` -> "(Author1 et al., 2001; Author2 et al., 2002)"

# Figures

Figures can be included like this:
![Caption for example figure.\label{fig:example}](figure.png)
and referenced from text using \autoref{fig:example}.

Figure sizes can be customized by adding an optional second parameter:
![Caption for example figure.](figure.png){ width=20% }

# Acknowledgements


# References