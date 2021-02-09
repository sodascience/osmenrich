library(tibble)
library(sf)
library(osmenrich)

if (!is.character(RCurl::getURL("www.google.com"))) skip("No internet connection found!")

# Set servers
options(osrm.server = "http://localhost:8080/")

# skip test if they don't exist
if (!url_available(getOption("osrm.server"))) {
  skip("Nginx server is unavailable!")
}

sf_people <-
  tribble(
    ~person, ~id,  ~lat,  ~lon, ~val,
    "Kees",    1, 52.09,  5.12,   5L,
    "Jan",     2, 52.08,  5.13,   2L
  ) %>%
  st_as_sf(coords = c("lon", "lat"), crs = 4326)

sf_bins <-
  tribble(
    ~id,  ~lat,  ~lon,
    1,   52.01,  5.13,
    2,   52.04,  5.14,
  ) %>%
  st_as_sf(coords = c("lon", "lat"), crs = 4326)

test_that("Walking distance and duration function", {
  res_duration <- duration_by_foot(sf_people, sf_bins)
  res_distance <- distance_by_foot(sf_people, sf_bins)

  expect_equal(res_duration[2][1], 166.1)
  expect_equal(res_distance[3], 11569)
})

test_that("Driving distance and duration function", {
  res_duration <- duration_by_car(sf_people, sf_bins)
  res_distance <- distance_by_car(sf_people, sf_bins)

  expect_equal(res_duration[2][1], 12.2)
  expect_equal(res_distance[3], 11708)
})

test_that("Cycling distance and duration function", {
  res_duration <- duration_by_bike(sf_people, sf_bins)
  res_distance <- distance_by_bike(sf_people, sf_bins)

  expect_equal(res_duration[2][1], 50.8)
  expect_equal(res_distance[3], 8106)
})