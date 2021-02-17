#' @name enrich
#' @title Enrich `sf` object with OSM data
#' @description Perform enriched query on osm and add as new column.
#'
#' The enrichment call works in the following way: an `enriched_overpass_query`
#' (e.g. `waste_query`) is created and then a new column is added by specifying
#' the name of the column (`"waste_baskets = waste_query"`). This call
#' also works with more than one queries.
#'
#' @param name the column name of the feature to be added
#' @param dataset target `sf` dataset to enrich with this package
#' @param key target OSM feature key to add, see \link{add_osm_feature}
#' @param value target value for OSM feature key to add, see \link{add_osm_feature}
#' @param type `character` the osm feature type or types to consider
#' (e.g., points, polygons), see details
#' @param distance `character` the distance metric used, see details
#' @param kernel `function` the kernel function used, see details
#' @param ... `enriched_overpass_query` column or columns to add
#' @param .verbose `bool` whether to print info during enrichment
#'
#' @examples
#' \donttest{
#'
#' # Enrich data creating new column `waste_baskets`
#' sf_enriched <- dataset %>%
#'   enrich_osm(
#'     name = "waste_baskets",
#'     key = "amenity",
#'     value = "waste_basket",
#'     type = "points",
#'     distance = "walking_duration",
#'     kernel = "uniform",
#'     r = 100
#'   )
#' }
#'
#' @seealso \code{\link{enrich_opq}}
#' @note
#' If you want to get a large number of points make sure to set the
#' .timeout (time before request times out) and .memsize (maxmimum
#' size of the request) arguments for the Overpass server and set
#' the "max-table-size" argument correctly when starting the
#' OSRM server(s).
#' @export
enrich_osm <- function(
                       dataset,
                       name = NULL,
                       key = NULL,
                       value = NULL,
                       type = "points",
                       distance = "spherical",
                       kernel = "uniform",
                       ...,
                       .verbose = TRUE) {
  if (is.null(name)) stop("Enter a query name.")
  if (length(name) > 1) {
    stop("You can enrich one query at the time only.")
  } else {
    query <- enrich_opq(
      dataset, name, key, value, type,
      distance, kernel, .verbose, ...
    )
    enriched_data <- data_enrichment(
      dataset, query, name, .verbose
    )
    return(enriched_data)
  }
}

#' @keywords internal
data_enrichment <- function(data, query, colname, .verbose = TRUE) {
  # check inputs
  if (!is(data, "sf")) stop("Data should be sf object.")
  check_enriched_opq(query)

  # extract the feature points and/or centroids
  # only download points if only points are requested
  if (length(query[["type"]]) == 1 && query[["type"]] == "points") {
    attr(query, "nodes_only") <- TRUE
  }
  if (.verbose) cat(sprintf(" Downloading data for %s... ", colname))
  dat <- osmdata::osmdata_sf(q = query)
  if (.verbose) {
    cat("Done.\n", sprintf(
      "Downloaded %i points, %i lines, %i polygons, %i mlines, %i mpolygons.\n",
      if (is.null(dat$osm_points)) 0 else nrow(dat$osm_points),
      if (is.null(dat$osm_lines)) 0 else nrow(dat$osm_lines),
      if (is.null(dat$osm_polygons)) 0 else nrow(dat$osm_polygons),
      if (is.null(dat$osm_multilines)) 0 else nrow(dat$osm_multilines),
      if (is.null(dat$osm_multipolygons)) 0 else nrow(dat$osm_multipolygons)
    ))
  }

  # Get feature sf::geometry
  first <- TRUE
  for (type in query$type) {
    geometry <- dat[[paste0("osm_", type)]][["geometry"]]
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

  if (.verbose) cat(sprintf(" Computing distance matrix for %s...", colname))

  # Get reference sf::geometry
  ref_geometry <- sf::st_geometry(
    sf::st_transform(data, crs = 4326)
  ) # force WGS84

  # Create matrix ref <-> ftr
  distance_mat <- distance_matrix(
    distancename = query[["distance"]],
    distancefun = query[["distancefun"]],
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

  if (.verbose) cat(sprintf("Done.\n Adding %s to data.\n", colname))
  data[[colname]] <- feature
  return(data)
}

#' @keywords internal
distance_matrix <- function(
                            distancename,
                            distancefun,
                            ref_geometry,
                            ftr_geometry) {
  # If "spherical" then no call to OSRM necessary
  if (distancename == "spherical") {
    matrix <- distancefun(ref_geometry, ftr_geometry)
    return(matrix)
  }

  if (!check_osrm_limits(src = ref_geometry, dst = ftr_geometry)) {
    matrix <- distancefun(ref_geometry, ftr_geometry)
  } else {
    print("Splitting main call and creating sub-calls...")
    tot_nrows <- nrow(ref_geometry) * nrow(sf::st_coordinates(ftr_geometry))
    first <- TRUE
    chunk_size <- 20000
    # TODO: improve function
    for (i in seq(1, tot_nrows, chunk_size)) {
      seq_size <- chunk_size
      if ((i + seq_size) > tot_nrows) seq_size <- tot_nrows - i + 1
      # matrix <- distancefun(ref_geometry[i:], ftr_geometry[i:,:])
      if (first) {
        result <- matrix
        first <- FALSE
      } else {
        result <- rbind(result, matrix)
      }
    }
  }
}
