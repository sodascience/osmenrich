#' Compute distance and duration measures matrix using the OSRM server.
#'
#' Uses an OSRM (open source routing machine) instance to compute distance
#'   measures between source geometry and destination geometry. Measures
#'   available are those enabled by the OSRM API service: walking, driving and
#'   cycling. These measures are available in the following metrics:
#'   duration (in minutes) and distance (in meters).
#'
#' @param src `sfc_POINT` `sfc` object with the source points.
#' @param dst `sfc_POINT` `sfc` object with the destination points.
#' @param profile `character` `str` object indicating the OSRM profile needed.
#' @return `matrix` Matrix with measures (distances or durations)
#'   from src (rows) to dst (cols).
#'
#' @family Functions to measure distance and duration.
#' @seealso [enrich_opq()], [osrm_table()]
#'
#' @name distance_funs
#' @export

#' @rdname distance_funs
#' @export
duration_by_foot <- function(src, dst) {
  matrix <- osrm_duration(src, dst, "walking")
  return(matrix)
}

#' @rdname distance_funs
#' @export
distance_by_foot <- function(src, dst) {
  matrix <- osrm_distance(src, dst, "walking")
  return(matrix)
}

#' @rdname distance_funs
#' @export
duration_by_car <- function(src, dst) {
  matrix <- osrm_duration(src, dst, "driving")
  return(matrix)
}

#' @rdname distance_funs
#' @export
distance_by_car <- function(src, dst) {
  matrix <- osrm_distance(src, dst, "driving")
  return(matrix)
}

#' @rdname distance_funs
#' @export
duration_by_bike <- function(src, dst) {
  matrix <- osrm_duration(src, dst, "cycling")
  return(matrix)
}

#' @rdname distance_funs
#' @export
distance_by_bike <- function(src, dst) {
  matrix <- osrm_distance(src, dst, "cycling")
  return(matrix)
}

#' @rdname distance_funs
#' @export
osrm_distance <- function(src, dst, profile) {
  # create sf from src and dst
  if (!is(src, "sf")) {
    src <- sf::st_sf(geometry = src)
  }
  if (!is(dst, "sf")) {
    dst <- sf::st_sf(geometry = dst)
  }

  # retrieve the calculated metric's matrix
  distance_mat <- osrm_table(
    src = src,
    dst = dst,
    measure = "distance",
    osrm_profile = profile
  )$distances
  distance_mat[is.na(distance_mat)] <- Inf
  return(distance_mat)
}

#' @rdname distance_funs
#' @export
osrm_duration <- function(src, dst, profile) {
  # create sf from src and dst
  if (!is(src, "sf")) {
    src <- sf::st_sf(geometry = src)
  }
  if (!is(dst, "sf")) {
    dst <- sf::st_sf(geometry = dst)
  }

  # retrieve the calculated metric's matrix
  duration_mat <- osrm_table(
    src = src,
    dst = dst,
    measure = "duration",
    osrm_profile = profile
  )$durations
  duration_mat[is.na(duration_mat)] <- Inf
  return(duration_mat)
}
