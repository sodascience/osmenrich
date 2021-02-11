<p align="center">
  <img src="man/figures/logo.png" width="250px"></img>
  <!-- badges: start
  <br/>
  <span>
    <a href="https://travis-ci.org/vankesteren/tensorsem"><img src="https://travis-ci.org/vankesteren/tensorsem.svg?branch=master"></img></a>
    <a href="https://zenodo.org/badge/latestdoi/168356695"><img src="https://zenodo.org/badge/168356695.svg" alt="DOI"></a>
    [![R build status](https://github.com/sodascience/osmenrich/workflows/R-CMD-check/badge.svg)](https://github.com/sodascience/osmenrich/actions)
    [![Codecov test coverage](https://codecov.io/gh/sodascience/osmenrich/branch/master/graph/badge.svg)](https://codecov.io/gh/sodascience/osmenrich?branch=master)
  </span>
  badges: end -->
</p>
<br/>

# Enrich geocoded data using openstreetmaps (Coming soon!!!)

![Github Action test](https://github.com/sodascience/osmenrich/workflows/.github/workflows/R-CMD-check.yaml/badge.svg)

The goal of `osmenrich` is to easily enrich geocoded data
(`latitude`/`longitude`) with geographic features from OpenStreetMap (OSM).
The main language of the package is `R` and this package is designed to work
with the `sf` and `osmdata` packages for collecting and manipulating geodata.

## Installation

To install the package, run:

```r
remotes::install_github("sodascience/osmenrich")
```

or, for the development version, run:

```r
remotes::install_github("sodascience/osmenrich@develop")
```

This will use the default public APIs for OSM data and routing (for computing
driving/walking distances and durations). __Do not use `osmenrich` with
default APIs for large datasets!__ If you want to learn how to use `osmenrich`
for large queries follow the instructions in section
[Local API Setup](#local-api-setup) below.

## Usage

### Simple enrichment example

Let's enrich a spatial (`sf`) dataset (`sf_example`) with the number of waste
baskets in a radius of 100 meters from each of the point specified in a
dataset:

```r
# Import libraries
library(tidyverse)
library(sf)
library(osmdata)
library(osmenrich)

# Create an example dataset to enrich
sf_example <-
  tribble(
    ~person, ~id,  ~lat,  ~lon, ~val,
    "Alice",   1, 52.12,  5.09,   5L,
    "Bob",     2, 52.13,  5.08,   2L
  ) %>%
  sf::st_as_sf(coords = c("lon", "lat"), crs = 4326)

# Print it
sf_example
#> Simple feature collection with 2 features and 3 fields
#> geometry type:  POINT
#> dimension:      XY
#> bbox:           xmin: 5.08 ymin: 52.12 xmax: 5.09 ymax: 52.13
#> CRS:            EPSG:4326
#> # A tibble: 2 x 4
#>  person    id   val     geometry
#> * <chr>  <dbl> <int>  <POINT [°]>
#> 1 Alice      1     5 (5.09 52.12)
#> 2 Bob        2     2 (5.08 52.13)
```

To enrich the `sf_example` dataset with "waste baskets" in a 100m radius, we
create a query using the `enrich_osm()` function. This function uses the
bounding box created by the points present in the example dataset and searches
for the specified `key = "amenity"` and `value = "waste_basket`. We also add a
custom `name` for the newly created column and specify the radius (`r`) used
in the search. See
[Map Features on the website of OSM](https://wiki.openstreetmap.org/wiki/Map_features)
for a complete list of `key` and `value` combinations.

```r
# Simple OSMEnrich query
sf_example_simple <- sf_example %>%
  enrich_osm(
    name = "waste_baskets",
    key = "amenity",
    value = "waste_basket",
    r = 100
  )
#> Downloading data for waste_baskets... Done.
#> Downloaded 26 points, 0 lines, 0 polygons, 0 mlines, 0 mpolygons.
#> Computing distance matrix for wastebaskets...Done.
#> Adding waste_baskets to data.

```

The resulting enriched dataset is a `sf` object and can be printed as usual
and we can inspect the newly added column `waste_baskets`.

```r
sf_example_enriched
#> Simple feature collection with 2 features and 4 fields
#> geometry type:  POINT
#> dimension:      XY
#> bbox:           xmin: 5.08 ymin: 52.12 xmax: 5.09 ymax: 52.13
#> CRS:            EPSG:4326
#>  A tibble: 2 x 5
#>  person    id   val     geometry waste_baskets
#> * <chr>  <dbl> <int>  <POINT [°]>         <int>
#> 1 Alice      1     5 (5.09 52.12)             3
#> 2 Bob        2     2 (5.08 52.13)             0
```


## Local API setup

OSM enrichment can ask for a lot of data, which can overload public APIs. If
you intend to enrich large amounts of data or compute routing distances (e.g.,
driving duration) between many points, you should set up a local API endpoint.

We provide a `docker-compose` workflow for this in the separate
[osmenrich_docker
repository](https://github.com/sodascience/osmenrich_docker). Use the `README`
on the repository for setup instructions.


<img src="man/figures/docker.png" width="250px"></img>

<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community an amazing place to
learn, inspire, and create. Any contributions you make are **greatly
appreciated**.

In this project we use the
[Gitflow workflow](https://nvie.com/posts/a-successful-git-branching-model/)
to help us with continious development. Instead of having a single
`master`/`main` branch we use two branches to record the history of the
project: `develop` and `master`. The `master` branch is used only for the
official releases of the project, while the `develop` branch is used to
integrate the new features developed. Finally, `feature` branches are used to
develop new features or additions to the project that will be `rebased and
squash` in the `develop` branch.

The workflow to contribute with Gitflow becomes:

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/<AmazingFeature>`)
3. Commit your Changes (`git commit -m 'Add some <AmazingFeature>'`)
4. Push to the Branch (`git push origin feature/<AmazingFeature>`)
5. Open a Pull Request

## License and citation

The `osmenrich` package is published under the MIT license. When using
`osmenrich` for academic work, please cite:

```
Will soon follow.
```

<!-- CONTACT -->
## Contact

This package is developed and maintained by the [ODISSEI Social Data Science
(SoDa)](https://odissei-data.nl/nl/soda/) team.

Do you have questions, suggestions, or remarks? File an issue in our issue
tracker or feel free to contact [Erik-Jan van
Kesteren](https://github.com/vankesteren)
([@ejvankesteren](https://twitter.com/ejvankesteren)) or [Leonardo
Vida](https://github.com/leonardovida)
([@leonardojvida](https://twitter.com/leonardojvida))

<img src="man/figures/word_colour-l.png" width="250px"></img>
