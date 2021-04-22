---
title: 'Osmenrich: An R package to enrich geocoded data'
tags:
  - R
  - geospatial data
  - goespatial
  - sf
  - openstreetmap
  - osmdata
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

The `osmenrich` package provides a user-friendly way to enrich geographic datasets in `R`, for example observations on a map, with geographic features around those observations and to weight these features by their distance or duration from the observations. This package builds on existing infrastructure to interface with OpenStreetMap (`osmdata`, @osmdata:2017), and works well with the existing ecosystem of packages for (geospatial) data analysis, namely `sf` [@sf:2018] and the `tidyverse` [@tidyverse:2019]. Thus, this package streamlines and standardizes the process going from a raw dataset with observations and locations to a `tidy` [@tidy-data:2014], rich dataset with multiple relevant geographical features about those locations. Figure \autoref{fig:workflow} shows graphically the basic workflow of `osmenrich`.

The R package `osmenrich` is available on [GitHub](https://github.com/sodascience/osmenrich).

![Basic workflow of `osmenrich`. \label{fig:workflow}](figures/introduction.png)

# Statement of need

Geographic data is valuable in research where the environment influences the process under investigation. For example, the `osmenrich` package is useful in the analysis of data retrieved from citizen science projects such as [plastic spotter](https://www.plasticspotter.nl/) or the [great backyard bird count](https://www.birdcount.org/). At the same time, within the R ecosystem multiple software solutions exist for extracting data from geographic information systems [@osmdata:2017, @googleway:2020, @mapbox:2020]. However, in order to include these data in further analysis (e.g., universal kriging in `gstat`, @gstat:2004), these data often need further processing and, crucially, _aggregation_. Within this problem space, the contributions of `osmenrich` are as follows:

- Creates a user-friendly interface to OpenStreetMap, abstracting away the necessary API calls.
- Defines standardized ways to aggregate geographic information based on kernels (see \autoref{sec:kern}).
- Allows distance measures based on routing, such as duration by foot or distance by car (see \autoref{sec:rout}).

Using this package, researchers can focus on research questions, rather than spending time figuring out how to aggregate geographic data. The `osmenrich` package can be especially useful answering questions relative to identifying **features within a determined distance from observations that are relevant to explain the process under investigation**.

Before introducing the main function and tools of this package, we introduce the grammar used in this paper. We call "_reference points_" the objects with geocoded data that a researcher wants to enrich, while "_feature points_" the objects the researcher is interested in retrieving. Thus, if a dataset contains geocoded data, with this package one can extract information about real-world object around each of the objects contained in the data, compute their distance/duration from the objects and then enrich the dataset with this information. The result is a `tidy sf` dataset.

# Main function

To enrich data, the `osmenrich` package uses its main function `enrich_osm()`. This function takes a dataset containing geocoded _reference points_ in `sf` format, retrieved specified points from a local or remote OpenStreetMap server, computes the enrichment with the specified `kernel` parameters and outputs an enriched `sf` dataset. The `enrich_osm()` function uses the bounding box created by the _reference points_ from the input dataset and searches for the specified _feature points_ in OpenStreetMap using the parameters `key` and `value` within the radius `r` around each of the _reference points_. For each _reference points_ it uses the `kernel` parameter to compute the enrichment and finally adds a newly created column named using the variable `name` containing the enriched data. See section \autoref{sec:usage} for an example usage of this function.

# Kernels
\label{sec:kern}

Kernels are a tool to weight and aggregate the features retrieved from OpenStreetMap and play a center role in the data enrichment process used in `osmenrich`. Kernels first weight the points retrieved by their distances (or durations) from the reference points and then convert these vectors into single numbers. This conversion is done by just specifying a kernel, or by specifying a kernel and the aggregation function used to reduce these weighted vectors of points into single numbers.

There are three main variables involved in the specification of a kernel:

1. The radius parameter `r`, indicates the distance from each of the observation points on which the kernel will be applied.
2. The kernel parameter `kernel`, indicates the kernel function to use in weighting the retrieved points within the specified radius. The `osmenrich` package provides three different kernels to be used out-of-the-box (`uniform`, `gaussian` and `parabola`) and defaults to `kernel = uniform`. However, the user can also specify custom-made kernels as long as they follow the .
  ![Weighting functions included in `osmenrich` kernels. \label{fig:kernels}](figures/kernels.png)
3. The aggregation function parameter `reduce_fun`, is used to choose the aggregation function that will be applied to the weighted points. This parameters defaults to `reduce_fun = sum`, however it accepts any standard `R` function, such as `mean` or `median`.

Specifying these variables in the `enrich_osm()` function, allows the user to choose the specify the type of weighting and aggregation to be applied on the features retrieved from OpenStreetMap.

```R
enrich_osm(
  [...],
  r = 100, # radius for features retrieval
  kernel = 'gaussian', # weighting function
  reduce_fun = 'mean', # aggregation function
)
```

# Routing
\label{sec:rout}

To retrieve _feature points_ around the _reference points_ and the distances (or durations) between these points, the `osmenrich` package makes use of an instance of OpenStreetMap and one or more instances of Open Source Routing Machine (OSRM) respectively.

The basic data enrichment will work without having to setup any one of these server locally, thanks to publicly available servers. However, for large data enrichment tasks and for tasks involving the computation of durations between _reference points_ and _feature points_ and/or the computation of custom distances or durations between these points (such as the distances between two points computed on a walking distance or cycling), the setup of one or more of these servers is required.

We created a [GitHub repository](https://github.com/sodascience/osmenrich_docker) hosting the instruction and the `docker_compose.yml` files needed to setup these servers. To facilitate the routing of users to the right setup for their need, we provide three use cases and their respective recommended setup:

1. **Base use-case**. The user only wants to enrich adding nearby features. The user is not interested in distances nor durations as measured by OSRM servers. The setup of local or remote instance is not recommended.
2. **Normal use-case**. The user only wants to enrich adding features for a large area. The user might be interested in distances but does not require a specific metric (i.e. car vs. foot vs. bike). Only the setup of the OpenStreetMap server is recommended. The OSRM connection will rely on public servers.
3. **Advanced use-case**. The user wants to enrich adding features for a large area and/or is interested in specific metrics for distances/durations (i.e. foot or bike). The setup of both the OpenStreetMap and OSRM servers is recommended.

```R
# Specify the address of local OSRM instance
# options(osrm.server = "http://localhost:<port>/")
# You can specify also the address of the Overpass (OSM) instance
# osmdata::set_overpass_url("http://localhost:<port>/api/interpreter")
enrich_osm(
  [...],
  distance = "distance_by_foot", # Specifying a routing using the OSRM server
)
```

# Full usage
\label{sec:usage}

`osmenrich` is available on [GitHub](https://github.com/sodascience/osmenrich) and can be installed and loaded into the R session with the remotes package from GitHub. Then the package can be loaded in the usual way:

```R
library(osmenrich)
```

TODO: Include the dataset in the package with usethis()

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
head(common_swift())
# Show the output of the command
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
# Show the output of the command
```

# Acknowledgements

TODO: This project was funded

# References
