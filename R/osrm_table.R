#' @name osrm_table
#' @title Get Travel Time Matrices Between Points
#' @description Build and send OSRM API queries to get travel time matrices
#'   between points. This function interfaces the \emph{table} OSRM service.
#'
#' @param src A data frame containing origin points identifiers, longitudes
#'   and latitudes (WGS84). It can also be a `SpatialPointsDataFrame`, a
#'   `SpatialPolygonsDataFrame` or an `sf` object. If so, row names are
#'   used as identifiers. If dst and src parameters are used,
#'   only pairs between scr/dst are computed.
#' @param dst A data frame containing destination points identifiers, longitudes
#'   and latitudes (WGS84). It can also be a `SpatialPointsDataFrame` a
#'   `SpatialPolygonsDataFrame` or an `sf` object. If so, row names are used
#'   as identifiers.
#' @param measure A character indicating what measures are calculated. It can
#'   be "duration" (in minutes), "distance" (meters), or both c('duration',
#'   'distance'). The public server only allows "duration".
#' @param osrm_server The base URL of the routing server. Uses
#'   `getOption("osrm.server")` to retrieve the current server by default.
#' @param osrm_profile The routing profile to use, e.g. "car", "bike" or "foot"
#'   (when not using the public server). Uses `getOption("osrm.profile")` to
#'   retrieve the default profile ("car").
#'
#' @return A list containing 3 data frames is returned.
#'   `durations` is the matrix of travel times (in minutes);
#'   `sources` and `destinations` are the coordinates of
#'   the origin and destination points actually used to compute the travel
#'   times (WGS84).
#'
#' @seealso [set_server_profile()]
osrm_table <- function(src = NULL, dst = NULL, measure = "duration",
                       osrm_profile = "driving",
                       osrm_server = getOption("osrm.server")) {
    # Set and get server and profile
    set_server_profile(
        server = osrm_server,
        profile = osrm_profile
    )
    osrm_server <- getOption("osrm.server")
    osrm_profile <- getOption("osrm.profile")

    tryCatch(
        {
            src <- transform_to_df(src)
            dst <- transform_to_df(dst)

            # Build the query
            loc <- rbind(src, dst)
            req <- paste(
                create_osrm_input_table(
                    loc = loc,
                    osrm_server = osrm_server,
                    osrm_profile = osrm_profile
                ),
                "?sources=",
                paste(0:(nrow(src) - 1), collapse = ";"),
                "&destinations=",
                paste(nrow(src):(nrow(loc) - 1), collapse = ";"),
                sep = ""
            )

            # annotation mngmnt
            annotations <- paste0(
                "&", "annotations=", paste0(measure, collapse = ",")
            )

            # Request
            req <- utils::URLencode(paste0(req, annotations))

            # Retrieve result from OSRM server
            i <- 0
            while (i != 10) {
                x <- try(
                    {
                        output_osrm <- RCurl::getURL(req)
                        output_osrm <- jsonlite::fromJSON(output_osrm)
                    },
                    silent = T
                )
                # If RCurl fails then try-error is raised
                if (class(x) == "try-error") {
                    Sys.sleep(1)
                    i <- i + 1
                } else {
                    break
                }
            }

            # Check results
            if (is.null(output_osrm$code)) {
                e <- simpleError(output_osrm$message)
                stop(e)
            } else {
                e <- simpleError(
                    paste0(
                        output_osrm$code, "\n", output_osrm$message
                    )
                )
                if (output_osrm$code != "Ok") {
                    stop(e)
                }
            }

            output <- list()
            if (!is.null(output_osrm$durations)) {
                # Get and format duration table
                output$durations <- format_osrm_output_table(
                    output_osrm, src, "durations"
                )
            }
            if (!is.null(output_osrm$distances)) {
                # Get and format distance table
                output$distances <- format_osrm_output_table(
                    output_osrm, dst, "distances"
                )
            }
            output$sources <- format_coord_table(
                output_osrm, src, "sources"
            )
            output$destinations <- format_coord_table(
                output_osrm, dst, "destinations"
            )
            return(output)
        },
        error = function(e) {
            message("The OSRM server ", osrm_server, " returned an error:\n", e)
        }
    )
    return(NULL)
}
