library(tibble)
library(sf)
library(osmdata)

# Skip tests if connection to internet is not available
if (!is.character(RCurl::getURL("www.google.com")))
  skip("No internet connection found!")

# Create sf used in tests
sf_example <-
  tribble(
    ~person, ~id,  ~lat,  ~lon, ~val,
    "Kees",    1, 52.09,  5.12,   5L,
    "Jan",     2, 52.08,  5.13,   2L
  ) %>%
  st_as_sf(coords = c("lon", "lat"), crs = 4326)

test_that("enrich_osm() test if example enrichment works", {
  sf_enriched <- sf_example %>%
    enrich_osm(
      name = "waste_baskets",
      key = "amenity",
      value = "waste_basket",
      r = 100,
      measure = "spherical"
    )

  expect_equal(class(sf_enriched$waste_baskets), "integer")
})
