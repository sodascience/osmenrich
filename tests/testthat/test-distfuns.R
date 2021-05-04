library(tibble)
library(sf)
library(osmenrich)

# Skip tests if connection to internet is not available
if (!is.character(RCurl::getURL("www.google.com")))
  skip("No internet connection found!")

# Set servers
options(osrm.server = "http://localhost:8080/")

# Skip test if they don't exist
if (!osmenrich::url_available(getOption("osrm.server"))) {
  server_available <- FALSE
  run_tests(server_available)
  skip("Nginx server is unavailable!")
} else {
  server_available <- TRUE
  run_tests(server_available)
}

# Create sf used in tests
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

# Run different tests depending on the connection available
run_tests <- function(server_available) {
  if (server_available == FALSE) {
    test_that("Driving distance and duration function", {
      res_duration <- duration_by_car(sf_people, sf_bins)
      res_distance <- distance_by_car(sf_people, sf_bins)

      expect_that(res_duration[1][1], is_a("numeric"))
      expect_that(res_distance[1][1], is_a("numeric"))
    })
  }
  else {
    test_that("Walking distance and duration function", {
      res_duration <- duration_by_foot(sf_people, sf_bins)
      res_distance <- distance_by_foot(sf_people, sf_bins)

      expect_that(res_duration[1][1], is_a("numeric"))
      expect_that(res_distance[1][1], is_a("numeric"))
    })

    test_that("Cycling distance and duration function", {
      res_duration <- duration_by_bike(sf_people, sf_bins)
      res_distance <- distance_by_bike(sf_people, sf_bins)

      expect_that(res_duration[1][1], is_a("numeric"))
      expect_that(res_distance[1][1], is_a("numeric"))
    })
  }
}
