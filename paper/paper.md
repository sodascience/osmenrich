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

The `osmenrich` package provides a user-friendly way to enrich geographic datasets in `R`, for example observations on a map, with geographic features around those observations. Additionally, it can weigh these features by their distance or (walking / driving / cycling) duration from the observations. This package builds on existing infrastructure to interface with OpenStreetMap (`osmdata`, Padgham et al., 2017), and works well with the existing ecosystem of packages for (geospatial) data analysis, namely `sf` [@sf:2018] and the `tidyverse` [@tidyverse:2019]. Thus, this package streamlines and standardizes the process going from a raw dataset with observations and locations to a `tidy` [@tidy-data:2014], rich dataset with multiple relevant geographical features about those locations. \autoref{fig:workflow} shows graphically the basic workflow of `osmenrich`.

The R package `osmenrich` is available on [GitHub](https://github.com/sodascience/osmenrich).

![Basic workflow of `osmenrich`. \label{fig:workflow}](figures/introduction.png)

# Statement of need

Geographic data is valuable in research where the environment influences the process under investigation. For example, the `osmenrich` package is useful in the analysis of data retrieved from citizen science projects such as [plastic spotter](https://www.plasticspotter.nl/) or the [great backyard bird count](https://www.birdcount.org/). At the same time, within the R ecosystem multiple software solutions exist for extracting data from geographic information systems [@osmdata:2017, @googleway:2020, @mapbox:2020]. However, to include these geographic data in further analysis (e.g. carrying out kriging in `gstat`, E. J. Pebesma, 2004), the data often need further processing and, crucially, _aggregation_. Within this problem space, the contributions of `osmenrich` are as follows:

- Creating a user-friendly interface to OpenStreetMap, abstracting away the necessary API calls (see section _Main function_).
- Defyining standardized ways to aggregate geographic information based on kernels (see section _Aggregation kernels_).
- Allowing distance measures based on routing, such as duration by foot or distance by car (see section _Routing_).

Using our package, researchers can focus on investigating research questions, rather than spending time figuring out how to aggregate geographic data. The `osmenrich` package is especially suited for questions surrounding interactions between a process and its close physical environemnt, such as gathering data within a determined distance from observations to improve a prediction process or to *XXX*.

Before describing the main function and features of this package, we introduce the grammar used in this paper. We call objects with geocoded data that a researcher wants to enrich "_reference objects_", while objects the researcher is interested in retrieving "_feature objects_". If a dataset contains geocoded data, the `osmenrich` package can extract information about real-world objects (_feature points_) around each of the _reference points_ contained in the dataset, compute the distance/duration between them and enrich the initial dataset with this information. The result is a `tidy sf` dataset.

# Main function

To enrich data, the `osmenrich` package uses the main function `enrich_osm()`. This function takes a dataset containing geocoded _reference objects_ in `sf` format, retrieves specified objects from a local or remote OpenStreetMap server (see _Routing_ section), computes the enrichment using specified parameters and outputs an enriched `sf` dataset.

```R
enrich_osm(
  dataset = sf_dataset,
  name = "waste",
  key = "amenity", # Syntax borrowed from OpenStreetMap
  value = "waste_basket", # Syntax borrowed from OpenStreetMap
  r = 100
)
```

The code listing above shows an example of a basic enrichment of reference points with the number of waste baskets in the surrounding 100 meters. Specifically, the function uses the bounding box created by the _reference objects_ from the input dataset and searches for the specified _feature objects_ in OpenStreetMap with parameters `key` and `value` within the radius `r` (in meters) around each of the _reference objects_. The `key` and `value` parameters are also used as tags in OpenStreetMap to describe physical features of map elements. The user is able to search for them using [official OpenStreetMap documentation](https://wiki.openstreetmap.org/wiki/Map_features). Finally the `enrich_osm` function creates a new column named after the parameter `name` containing the enriched data. See Section _Full usage example_ for an example usage of this function.

# Aggregation kernels

To convert the retrieved features to a single number per reference object, an aggregation step is performed by `osmenrich`. In the `enrich_osm` function, there are three parameters that control aggregation: `kernel`, `reduce_fun`, and `measure`.

The `kernel` determines the weight used in aggregating the retreived objects. Kernels first weight the points retrieved by their distances (or durations) from the reference points and then convert these vectors into single numbers. This conversion is done by specifying a kernel or by specifying a kernel and the aggregation function used to reduce these weighted vectors of points into single numbers.

There are three main variables involved in the specification of a kernel:

1. The radius parameter `r`, indicates the distance from each of the observation points on which the kernel will be applied.
2. The kernel parameter `kernel`, indicates the kernel function to use in weighting the retrieved points within the specified radius. The `osmenrich` package provides three different kernels to be used out-of-the-box (`uniform`, `gaussian` and `parabola`) and defaults to `kernel = uniform`. However, the user can also specify custom-made kernels as long as they follow the .
  ![Weighting functions included in `osmenrich` kernels. \label{fig:kernels}](figures/kernels.png)
3. The aggregation function parameter `reduce_fun`, is used to choose the aggregation function that will be applied to the weighted points. This parameters defaults to `reduce_fun = sum`, however it accepts any standard `R` function, such as `mean` or `median`.

Specifying these variables in the `enrich_osm()` function, allows the user to choose the specify the type of weighting and aggregation to be applied on the features retrieved from OpenStreetMap.

```R
enrich_osm(
  [...],
  r = 100, # Radius for features objects retrieval
  kernel = "gaussian", # Weighting function
  reduce_fun = "mean" # Aggregation function
)
```

# Routing

To retrieve _feature points_ around the _reference points_ and the distances (or durations) between these points, the `osmenrich` package makes use of an instance of OpenStreetMap and one or more instances of Open Source Routing Machine (OSRM) respectively.

The basic data enrichment will work without having to setup any one of these server locally, thanks to publicly available servers. However, for large data enrichment tasks and for tasks involving the computation of durations between _reference points_ and _feature points_ and/or the computation of custom distances or durations between these points (such as the distances between two points computed on a walking distance or cycling), the setup of one or more of these servers is required.

We created a [GitHub repository](https://github.com/sodascience/osmenrich_docker) hosting the instruction and the `docker_compose.yml` files needed to setup these servers. To facilitate the routing of users to the right setup for their need, we provide three use cases and their respective recommended setup:

1. **Base use-case**. The user only wants to enrich adding nearby features. The user is not interested in distances nor durations as measured by OSRM servers. The setup of local or remote instance is not recommended.
2. **Normal use-case**. The user only wants to enrich adding features for a large area. The user might be interested in distances but does not require a specific metric (i.e. car vs. foot vs. bike). Only the setup of the OpenStreetMap server is recommended. The OSRM connection will rely on public servers.
3. **Advanced use-case**. The user wants to enrich adding features for a large area and/or is interested in specific metrics for distances/durations (i.e. foot or bike). The setup of both the OpenStreetMap and OSRM servers is recommended.

Finally, to specify which distance metric to use, the user can set the parameter `distance` to the desired choice as in the example below.

```R
# Specify the address of local OSRM instance
# options(osrm.server = "http://localhost:<port>/")
# You can specify also the address of the Overpass (OSM) instance
# osmdata::set_overpass_url("http://localhost:<port>/api/interpreter")
enrich_osm(
  [...],
  distance = "distance_by_foot" # Specifying a routing using the OSRM server
)
```

# Full usage example

`osmenrich` is available on [GitHub](https://github.com/sodascience/osmenrich) and can be installed and loaded into the R session with the remotes package from GitHub. Then the package can be loaded in the usual way:

```R
library(osmenrich)
```

As a brief example, suppose we have a dataset of common swift's nests provided openly by the city of Utrecht, the Netherlands. We want to enrich this dataset retrieving a proxy of natural material availability. For the sake of this example, we retrieve only "trees", as they represent a close enough proxy to natural materials. However, we could easily retrieve other data types, using the available list on OpenStreetMap at [Map Features](https://wiki.openstreetmap.org/wiki/Map_features)

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

bird_sf
# Show the output of the command
```

# Acknowledgements

# References
