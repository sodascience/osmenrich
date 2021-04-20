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

Our package provides a user-friendly way to enrich geographic datasets in `R`, for example observations on a map, with geographic features around those observations. This package builds on existing infrastructure to interface with OpenStreetMaps (`osmdata`, @osmdata:2017), and works well with the existing ecosystem of packages for (geospatial) data analysis, namely `sf` [@sf:2018] and the `tidyverse` [@tidyverse:2019]. The `osmenrich`  package streamlines and standardizes the process going from a raw dataset with observations and locations to a `tidy` [@tidy-data:2014], rich dataset with multiple relevant geographical features about those locations. Figure \autoref{fig:workflow} shows graphically the basic workflow of `osmenrich`.

The R package `osmenrich` is available on [GitHub](https://github.com/sodascience/osmenrich).

![Basic workflow of `osmenrich`. \label{fig:workflow}](figure-01.png)

# Statement of need

Geographic data is valuable in research where the environment influences the process under investigation. For example, the `osmenrich` package is useful in the analysis of data retrieved from citizen science projects such as [plastic spotter](https://www.plasticspotter.nl/) or the [great backyard bird count](https://www.birdcount.org/). At the same time, multiple software solutions exist for extracting data from geographic information systems [@osmdata:2017] (MORE CIT). However, in order to include these data in further analysis (e.g., universal kriging in `gstat`, citation), these data often need further processing and, crucially, _aggregation_. Within this problem space, the contributions of `osmenrich` are as follows:

- Creates a user-friendly interface to OpenStreetMaps, abstracting away the necessary API calls.
- Defines standardized ways to aggregate geographic information based on kernels (see \autoref{sec:kern}).
- Allows distance measures based on routing, such as duration by foot or distance by car (see \autoref{sec:rout}).

In this way, researchers can focus on the research questions themselves, rather than spending time figuring out how to aggregate geographic data: which features at which distance are relevant for the process under investigation?

To enrich data, the `osmenrich` package uses its main function `enrich_osm()`. This function takes XXX and XXX to output XXX.

# Kernels
\label{sec:kern}

Kernels are a tool to weight and aggregate the features retrieved from OpenStreetMap and play a center role in the data enrichment process used in `osmenrich`. Specifying the kernel variable in `enrich_osm()` allows to choose the kernel function applied on the features retrieved from OpenStreetMap.

In detail, kernels first weight the points retrieved by their distances (or durations) from the reference points and then convert these vectors into single numbers. In this package, this conversion can be done by just specifying a kernel, or by specifying a kernel and the aggregation function used to reduce these weighted vectors of points into single numbers.

The `osmenrich` package provides three different kernels to be used out-of-the-box (`uniform`, `gaussian` and `parabola`). For each of this kernels, and also in case the user created a custom kernel, the aggregation function can be specified by setting the variable `reduce_fun` to any standard `R` function, such as, but not limited to, `sum`, `mean` or `median`.

# Routing
\label{sec:rout}

To retrieve feature points and the distances from these points, the `osmenrich` package makes use of a public test instance of OpenStreetMap and OSRM respectively. The OpenStreetMap server is used to retrieve features points and can also be .

The OSRM server server to query the driving distances (distance = "distance_by_car"). Follow the instructions in section osmenrich Docker repository to set it up. Otherwise, out-of-the-box this package will support querying only driving distances. If you are interested in querying distances or durations for other means of transportation, you will need to set up local OSRM instances.

# Usage

`osmenrich` is available on [GitHub](https://github.com/sodascience/osmenrich) and can be installed and loaded into the R session using:

```R
# install.packages("remotes") # To install osmenrich we need 'remotes'
# remotes::install_github("sodascience/osmenrich") # Main version
# remotes::install_github("sodascience/osmenrich@develop") # Development version
library(osmenrich)
```

As a brief example, suppose we have a dataset of common swift's nests provided openly by the city of Utrecht, the Netherlands. We want to enrich this dataset retrieving a proxy of natural material availability. For the sake of this example, we retrieve only "trees", as they represent a close enough proxy to natural materials. However, we could easily retrieve other data types, using the available list on OpenStreetMap at [Map Features](https://wiki.openstreetmap.org/wiki/Map_features)

```R
# Retireve points
data_url <- "https://ckan.dataplatform.nl/dataset/8ceaae10-fb90-4ec0-961c-ef02691bb861/resource/baae4cde-cf33-416b-aa4e-d0fba160eed9/download/gierzwaluwinventarisatie2014.csv"
# Conver points into sf
bird_sf <-
  read_csv(data_url) %>%
  drop_na(latitude, longitude, `aantal nesten`) %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326) %>%
  select(nestcount = "aantal nesten", geometry)
```

```R
bird_sf <-
  bird_sf %>%
  enrich_osm(
    name = "tree_1km",
    key = "natural",
    value = "tree",
    kernel = "gaussian",
    r = 1000
  )
```

```R
bird_sf
```

Kernel example

Routing example


# Acknowledgements


# References
