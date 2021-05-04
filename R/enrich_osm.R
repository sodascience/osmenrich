#' @name enrich
#' @title Enrich `sf` object with OSM data
#' @description Perform enriched query on OSM and add as new column.
#'
#' @param name the column name of the feature to be added
#' @param dataset target `sf` dataset to enrich with this package
#' @param key target OSM feature key to add, see [osmdata::add_osm_feature()]
#' @param value target value for OSM feature key to add, see
#'   [osmdata::add_osm_feature()]
#' @param type `character` the osm feature type or types to consider
#' (e.g., points, polygons), see details
#' @param distance `character` the distance metric used, see details
#' @param kernel `function` the kernel function used, see details
#' @param r The search radius used by the `kernel` function.
#' @param reduce_fun The aggregation function used by the `kernel` function to
#'   aggregate the retrieved data points.
#' @param control The list with configuration variables for the OSRM server.
#'   It contains `timeout`, defining the number of seconds before the request
#'   to OSRM times out, and `memsize`, defining the maximum size of the query to
#'   OSRM.
#' @param .verbose `bool` whether to print info during enrichment
#' @param ... Additional parameters to be passed into the OSM query, such as
#'   a user-defined kernel.
#'
#' @details `Type` represents the feature type to be considered. Usually this
#'   would be points, but polygons and multipolygons are also possible. This
#'   argument can also be a vector of multiple types. Non-point types will be
#'   converted to points using the `st_centroid` function from the `sf` package
#'   (NB this does not necessarily work well for all features!).
#'   Available options are:
#'   - points
#'   - lines
#'   - polygons
#'   - multilines
#'   - multipolygons
#'
#'   `Distance` represents the metric used to compute the distances between the
#'   rows in the dataset and the OSM features. `Duration` represents the metric
#'   that indicates the average duration to cover the distances between the
#'   rows in the dataset and the OSM features. The following metrics are
#'   available in this package, assuming that the OSRM server is setup as
#'   suggested in our guide at:
#'   https://github.com/sodascience/osmenrich_docker:
#'   - spherical
#'   - distance_by_foot
#'   - duration_by_foot
#'   - distance_by_car
#'   - duration_by_car
#'   - distance_by_bike
#'   - duration_by_bike
#'
#' `Kernel` is a kernel function from the `osmenrich` package to be used in
#'   weighing the features and the radius/distance where features are
#'   considered. For simply counting the number of occurrences within a radius,
#'   use `kernel_uniform` with radius `r`.
#'
#' For more details see the introductory vignette of `osmenrich`:
#'   \code{vignette("introduction", package = "osmenrich")}
#'
#' @examples
#' \dontrun{
#' # Load libraries
#' library(tidyverse)
#' library(sf)
#'
#' # Create example dataset
#' sf_example <-
#' tribble(
#'   ~person,  ~lat,   ~lon,
#'   "Alice",  52.12,  5.09,
#'   "Bob",    52.13,  5.08,
#'   ) %>%
#'   sf::st_as_sf(
#'   coords = c("lon", "lat"),
#'   crs = 4326
#'  )
#'
#' # Enrich data creating new column `waste_baskets`
#' sf_enriched <- sf_example %>%
#'   enrich_osm(
#'     name = "n_waste_baskets",
#'     key = "amenity",
#'     value = "waste_basket",
# '    type = "points",
# '    distance = "duration_by_foot",
# '    r = 100,
# '    kernel = "uniform",
#'     reduce_fun = sum
#'   )
#' }
#'
#' @seealso [enrich_opq()]
#' @note If you want to get a large number of points make sure to set the
#'   `.timeout` (time before request times out) and `.memsize` (maxmimum
#'   size of the request) arguments for the Overpass server and set
#'   the "max-table-size" argument correctly when starting the
#'   OSRM server(s).
#' @export
enrich_osm <- function(
                       dataset,
                       name = NULL,
                       key = NULL,
                       value = NULL,
                       type = "points",
                       distance = "spherical",
                       r = NULL,
                       kernel = "uniform",
                       reduce_fun = sum,
                       control = list(),
                       .verbose = TRUE,
                       ...) {
  if (is.null(name)) stop("Enter a query name.")
  if (length(name) > 1) {
    stop("You can enrich one query at the time only.")
  } else {
    control <- do.call("control_enrich", control)
    # Create query to OSM server
    query <- enrich_opq(
      dataset = dataset,
      name = name, key = key, value = value, type = type,
      distance = distance, r = r, kernel = kernel,
      reduce_fun = reduce_fun, control = control, .verbose = .verbose,
      ...
    )
    # Enrichment call
    enriched_data <- data_enrichment(
      ref_data = dataset, query = query, colname = name, .verbose = .verbose
    )
    return(enriched_data)
  }
}

#' @rdname enrich
#' @keywords internal
data_enrichment <- function(ref_data, query, colname, .verbose = TRUE) {
  # Check inputs
  if (!is(ref_data, "sf")) stop("Data should be sf object.")
  check_enriched_opq(query)

  # Extract the feature points and/or centroids
  # Only download points if only points are requested
  if (length(query[["type"]]) == 1 && query[["type"]] == "points") {
    attr(query, "nodes_only") <- TRUE
  }
  if (.verbose) {
    cli::cli_process_start(
      msg = cli::col_cyan(glue::glue("Downloading data for {colname}...")),
      msg_done = cli::col_green("Downloaded data for {colname}."),
      msg_failed = cli::col_red(glue::glue("Failed to download data for {colname}!"))
    )
  }

  # Retrieve data from OSM server
  ftr_data <- osmdata::osmdata_sf(q = query)
  if (.verbose) {
    cli::cli_process_done()

    cli::cli_alert_info(cli::col_cyan(sprintf(
      "Downloaded %i points, %i lines, %i polygons, %i mlines, %i mpolygons.",
      if (is.null(ftr_data$osm_points)) 0 else
        nrow(ftr_data$osm_points),
      if (is.null(ftr_data$osm_lines)) 0 else
        nrow(ftr_data$osm_lines),
      if (is.null(ftr_data$osm_polygons)) 0 else
        nrow(ftr_data$osm_polygons),
      if (is.null(ftr_data$osm_multilines)) 0 else
        nrow(ftr_data$osm_multilines),
      if (is.null(ftr_data$osm_multipolygons)) 0 else
        nrow(ftr_data$osm_multipolygons)
    )))
  }

  # Get feature sf::geometry
  first <- TRUE
  for (type in query$type) {
    geometry <- ftr_data[[paste0("osm_", type)]][["geometry"]]
    if (is.null(geometry)) next
    # Whatever the geometry, as long as not points use centroid
    # Here one could divide it depending on the geometry or choice of user
    if (type != "points") {
      geometry <- sf::st_centroid(geometry) # of_largest_polygon = T
    }
    if (first) {
      ftr_geometry <- geometry
      first <- FALSE
    } else {
      ftr_geometry <- c(ftr_geometry, geometry)
    }
  }

  if (.verbose) {
    cli::cli_process_start(
      msg = cli::col_cyan(glue::glue("Computing distance matrix for {colname}...")),
      msg_done = cli::col_green("Computed distance matrix for {colname}."),
      msg_failed = cli::col_red(glue::glue("Failed to compute distance matrix for {colname}!"))
    )
  }

  # Modify both ftr and ref to 4326
  options(warn=-1)
  ref_geometry <- sf::st_transform(ref_data, crs = 4326)
  # This command raises a warning due to different versions of GDAL
  # see: https://github.com/r-spatial/sf/issues/1419
  st_crs(ftr_geometry) <- 4326
  options(warn=0)

  # Create matrix ref <-> ftr
  distance_mat <- distance_matrix(
    distance_name = query[["distance"]],
    distance_fun  = query[["distancefun"]],
    ref_geometry = ref_geometry,
    ftr_geometry = ftr_geometry
  )

  # Apply the kernel function over the rows of the distance matrix
  apply_args <-
    c(
      list(
        X = distance_mat,
        MARGIN = 1,
        FUN = query[["kernelfun"]]
      ),
      query[["kernelpars"]]
    )
  feature <- do.call(what = apply, args = apply_args)

  if (.verbose) {
    cli::cli_process_done()
    cli::cli_alert_info(cli::col_cyan(glue::glue("Adding {colname} to data.")))
  }
  ref_data[[colname]] <- feature
  return(ref_data)
}

#' @rdname enrich
#' @keywords internal
distance_matrix <- function(distance_name,
                            distance_fun,
                            ref_geometry,
                            ftr_geometry) {
  # If "spherical" then no call to OSRM necessary
  if (distance_name == "spherical") {
    matrix <- sf::st_distance(ref_geometry, ftr_geometry)
    return(matrix)
  }

  if (!check_osrm_limits(src = ref_geometry, dst = ftr_geometry)) {
    matrix <- distance_fun(ref_geometry, ftr_geometry)
  } else {
    print("Splitting main call and creating sub-calls...")
    tot_nrows <- nrow(ref_geometry) * nrow(sf::st_coordinates(ftr_geometry))
    first <- TRUE
    chunk_size <- 20000
    for (i in seq(1, tot_nrows, chunk_size)) {
      seq_size <- chunk_size
      if ((i + seq_size) > tot_nrows) seq_size <- tot_nrows - i + 1
      matrix <- distance_fun(ref_geometry[i:(i+seq_size),],
                            ftr_geometry[i:(i+seq_size),])
      if (first) {
        result <- matrix
        first <- FALSE
      } else {
        result <- rbind(result, matrix)
      }
    }
  }
}

#' @rdname enrich
#' @keywords internal
control_enrich <- function(timeout = 300, memsize = 1073741824) {
  if (!is.numeric(timeout) || timeout <= 0) {
    stop("Value of 'timeout' must be > 0")
  }
  if (!is.numeric(memsize) || memsize <= 0) {
    stop("Value of 'memsize' must be > 0")
  }
  list(timeout = timeout, memsize = memsize)
}
