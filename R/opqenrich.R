#' Enrich an overpass query for column output
#'
#' @param name name of the enriched column
#' @param dataset target `sf` dataset to enrich with this package
#' @param key target OSM feature key to add, see \link{add_osm_feature}
#' @param value target value for OSM feature key to add, see \link{add_osm_feature}
#' @param type `character` the osm feature type or types to consider
#' (e.g., points, polygons), see details
#' @param distance `character` the distance metric used, see details
#' @param kernel `function` the kernel function used, see details
#' @param opq overpass query that is being enriched
#' @param r The search radius used by the `kernel` function.
#' @param reduce_fun The aggregation function used by the `kernel` function to
#'   aggregate the retrieved data points.
#' @param .verbose `bool` whether to print info during enrichment
#' @param ... Additional parameters to be passed into the OSM query, such as
#'   a user-defined kernel.
#'
#' @importFrom methods is
#' @rdname enrich_opq
#'
#' @seealso [osmenrich::enrich_osm]
#'
#' @export
enrich_opq <- function(
                       dataset,
                       name = NULL,
                       key = NULL,
                       value = NULL,
                       type = "points",
                       distance = "spherical",
                       r = 100,
                       kernel = "uniform",
                       reduce_fun = sum,
                       control = list(),
                       .verbose = TRUE,
                       ...) {
  opq <-
    dataset %>%
    add_bbox(r, control) %>%
    add_feature(key, value) %>%
    add_type(type) %>%
    add_distance(distance) %>%
    add_kernel(kernel, r, reduce_fun, ...)
  opq$kernel <- as.character(substitute(kernel))
  opq$name <- name
  opq$key <- key
  opq$value <- value
  invisible(opq)
}

#' @rdname enrich_opq
#' @export
add_bbox <- function(dataset, r, control) {
  if (is.null(dataset)) {
    stop("Specify a dataset to enrich.")
  }
  # Extract bbox and transform 3488 (meters)
  bbox_tmp <- sf::st_transform(sf::st_as_sfc(sf::st_bbox(dataset)), 3488)
  # Add buffer of distance
  bbox_tmp <- sf::st_buffer(x = bbox_tmp, dist = r)
  # Convert back to 4326  (lat, lon) and find bbox of polygon
  bbox <- sf::st_bbox(sf::st_transform(bbox_tmp, 4326))
  # Find bbox "limits", Overpass ignores after 7 digits
  ymax <- as.double(formatC(bbox["ymax"], digits = 7, format = "f"))
  ymin <- as.double(formatC(bbox["ymin"], digits = 7, format = "f"))
  xmax <- as.double(formatC(bbox["xmax"], digits = 7, format = "f"))
  xmin <- as.double(formatC(bbox["xmin"], digits = 7, format = "f"))
  # Set timeout 300 seconds, memsize = 1GiB if not set
  opq <- osmdata::opq(
    bbox = c(xmin, ymin, xmax, ymax),
    timeout = control$timeout,
    memsize = control$memsize
  )
  if (!is(opq, "enriched_overpass_query")) {
    class(opq) <- c(class(opq), "enriched_overpass_query")
  }
  invisible(opq)
}

#' @rdname enrich_opq
#' @export
add_feature <- function(opq, key, value) {
  if ((!is.character(key)) && (!is.character(value))) {
    stop("Key and value of the feature should be characters.")
  }
  keys <- data.frame(words = osmdata::available_features())
  sub_key <- substring(key, 1, 3)
  suggestions <- keys[grep(sub_key, keys$words), ]
  if (!key %in% osmdata::available_features()) {
    stop(paste0(
      "\nThe feature key '", key, "' is not recognized or not",
      "available in OSM.",
      "\nOtherwise, you can use `osmdata::available_features()`",
      "to display the list of supported features.",
      "\nThere might be similar options: \n",
      paste(suggestions, collapse = ", ")
    ))
  }
  # Check for "catch-all" term NULL to `osmdata`:
  # osmdata uses NULL as a wildcard "*" indicator to retrieve
  # all the tags attached to the `key`.
  if (!is.null(value)) {
    values <- data.frame(words = osmdata::available_tags(key))
    sub_val <- substring(value, 1, 3)
    suggestions_val <- values[grep(sub_val, values$words), ]
    if (!value %in% osmdata::available_tags(key)) {
      stop(paste0(
        "\nThe feature value '", value, "' is not recognized ",
        "or not available in OSM.",
        "\nYou can use `osmdata::available_tags(<feature_key>)`",
        "to retrieve a list of supported values for each key.",
        "\nSimilar values for feature key `", key, "``: \n",
        paste(suggestions_val, collapse = ", ")
      ))
    }
  }
  if (is.null(opq$bbox)) {
    stop("Bbox not present in overpass query.")
  }
  # Use bbox in opq to add feature
  opq <- osmdata::add_osm_feature(opq, key, value,
    key_exact = TRUE, value_exact = FALSE,
    match_case = FALSE
  )
  if (!is(opq, "enriched_overpass_query")) {
    class(opq) <- c(class(opq), "enriched_overpass_query")
  }
  invisible(opq)
}

#' @rdname enrich_opq
#' @export
add_type <- function(opq, type) {
  if (!is.character(type)) {
    stop("Type should be a character or character vector.")
  }
  if (!all(type %in% osm_types)) {
    stop(
      "Type(s) \"", paste0(type[!type %in% osm_types], collapse = "\", \""),
      "\" not available. Available options: \n- ",
      paste(osm_types, collapse = "\n- ")
    )
  }
  opq$type <- type
  if (!is(opq, "enriched_overpass_query")) {
    class(opq) <- c(class(opq), "enriched_overpass_query")
  }
  invisible(opq)
}

#' @rdname enrich_opq
#' @export
add_distance <- function(opq, distance) {
  if (!is.character(distance)) stop("Metric should be a character.")
  if (!distance %in% names(osmenrich_distancefuns)) {
    stop(
      "Measure ", distance, " not available. Available options: \n- ",
      paste(names(osmenrich_distancefuns), collapse = "\n- ")
    )
  }
  opq$distance <- distance
  opq$distancefun <- osmenrich_distancefuns[[distance]]
  if (!is(opq, "enriched_overpass_query")) {
    class(opq) <- c(class(opq), "enriched_overpass_query")
  }
  invisible(opq)
}

#' @rdname enrich_opq
#' @export
add_kernel <- function(opq, kernel, r, reduce_fun, ...) {
  if (!(class(kernel) == "function") && !is.character(kernel)) {
    stop(
      "Kernel should be either be chosen among the available options:\n- ",
      paste(names(osmenrich_kernelfuns), collapse = "\n- "),
      "\nOr should be a function of the form: `function(d, r, fun) fun(d,r)`"
    )
  }
  if (!(class(reduce_fun) == "function")) {
    stop("The reduce function should be a function (E.g. 'sum')")
  }
  if (class(kernel) == "function") {
    kernelfun <- kernel
    tryCatch(
      {
        isFALSE(length(kernelfun(c(1, 1, 1))) != 1)
      },
      error = function(e) {
        message("The kernel is not a recognized function.\n
  It should be of the form `function(d, r, fun) fun(d,r).\n
  Error: \n", e)
      }
    )
  }
  if (is.character(kernel)) {
    if (kernel %in% names(osmenrich_kernelfuns)) {

      # Match kernel function among pre-defined ones
      kernelfun <- osmenrich_kernelfuns[[kernel]]

      if (length(kernelfun(c(1, 1, 1))) != 1) {
        stop("Kernel should output scalar for vector input.")
      }
    } else {
      warning(
        "Kernel ", kernel, " not within default options. Available",
        "options: \n- ",
        paste(names(osmenrich_kernelfuns), collapse = "\n- "),
        "\nTrying to recognize kernel as custom function."
      )
    }
  }
  opq$kernel <- as.character(substitute(kernel))
  opq$kernelpars <- list(r, reduce_fun, ...)
  opq$kernelfun <- kernelfun
  if (!is(opq, "enriched_overpass_query")) {
    class(opq) <- c(class(opq), "enriched_overpass_query")
  }
  invisible(opq)
}

#' @keywords internal
check_enriched_opq <- function(opq) {
  if (!is(opq, "enriched_overpass_query")) {
    stop("Query is not an enriched overpass query. See ?enrich_opq.")
  }
  required <- c("type", "distance", "kernel")
  missings <- !required %in% names(opq)
  if (any(missings)) {
    stop(
      "Fields \"", paste0(required[missings], collapse = "\", \""),
      "\" missing from the query. See ?enrich_opq."
    )
  }
  return(TRUE)
}

#' @keywords internal
osmenrich_distancefuns <- list(
  "spherical" = sf::st_distance,
  "distance_by_foot" = distance_by_foot,
  "duration_by_foot" = duration_by_foot,
  "distance_by_car" = distance_by_car,
  "duration_by_car" = duration_by_car,
  "distance_by_bike" = distance_by_bike,
  "duration_by_bike" = duration_by_bike
)

#' @keywords internal
osm_types <- c("points", "lines", "polygons", "multilines", "multipolygons")

#' @keywords internal
osmenrich_kernelfuns <- list(
  "gaussian" = kernel_gaussian,
  "parabola" = kernel_parabola,
  "uniform" = kernel_uniform
)

#' @method print enriched_overpass_query
#' @export
print.enriched_overpass_query <- function(x, ...) {
  kernelpars_string <- ifelse(
    length(x$kernelpars) > 0,
    paste0("[", names(x$kernelpars), ": ", x$kernelpars, "]", collapse = ", "),
    ""
  )
  cat(
    "<enriched overpass query> \n",
    "\u00B7 Name:        ", x$name, "\n",
    "\u00B7 Features:    'key': ", x$key, "; 'value': ", x$value, "\n",
    "\u00B7 Type:        ", paste0(x$type, collapse = ", "), "\n",
    "\u00B7 Distance:    ", x$distance, "\n",
    "\u00B7 Kernel:      ", x$kernel, kernelpars_string,
    "\n ---\n",
    "\u00B7 BBox:        ", x$bbox, "\n"
  )
}
