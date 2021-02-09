#' @title Test if server set is available.
#'
#' @description The user should indicate the address where one or more instance
#' of the OSRM server are running. In case more instances are running at the
#' same time, we force the user to place them behind a reverse proxy (we force
#' to indicate only one server address). We further recommend to use our
#' default docker-compose configuration to have a working configuration
#' with three OSRM servers behind an nginx server
#' (https://github.com/sodascience/osmenrich_docker).
#'
#' If no servers are used, the default server from the OSRM project
#' (http://router.project-osrm.org/) will be used. This is not recommended
#' as this server is intended only for demo purposes, might fail in case of
#' overload and only returns distances for the driving profile.
#' @param profile The name of the profile
#' @return Set the `osrm.server` and the `osrm.profile`
#' The name of the profile will be used only if the server (via `osrm.server`)
#' is set. Otherwise, the default server will be used
#'
#' @keywords internal
#' @seealso \code{\link{osrmtable}} for the main function
set_server_profile <- function(server, profile) {
    # If server not set or not reachable use default server
    tryCatch(
        {
            if (is.null(server) || !url_available(server)) {
                osrm_server <- "http://router.project-osrm.org/"
                # options(
                #     osrm.server = paste0(
                #         osrm_server,
                #         "routed-",
                #         profile, "/"
                #     )
                options(osrm.server = osrm_server)
                options(osrm.profile = profile)
            } else {
                if (!is.null(server) && url_available(server)) {
                    options(osrm.profile = profile)
                }
            }
        },
        error = function(e) {
            message(paste("Server does not seem to exist or respond:", server))
            return(NULL)
        }
    )
}

#' @title Check if server is available
#' @keywords internal
#' @seealso \code{\link{set_server_profile}}
url_available <- function(u) {
    tryCatch(
        {
            httr::HEAD(u)
            TRUE
        },
        error = function(e) FALSE
    )
}

#' @title Take sf and transform it into a dataframe
#' @description Dataframes are necessary for the transformations
#' needed to query the osrm servers.
#' @keywords internal
#' @seealso \code{\link{osrmtable}}
transform_to_df <- function(sf) {
    coords_matrix <- sf::st_coordinates(sf)
    df <- data.frame(
        id = row.names(sf),
        lon = adjust_coord(coords_matrix[, 1]),
        lat = adjust_coord(coords_matrix[, 2]),
        stringsAsFactors = FALSE
    )
    names(df) <- c("id", "lon", "lat")
    return(df)
}

#' @title Build OSRM query applying google encryption algorithm if necessary
#' @keywords internal
#' @seealso \code{\link{osrmtable}} for the main function
create_osrm_input_table <- function(loc, osrm_server, osrm_profile) {
    # Check if user forgot to insert "/" at the end of the osrm.server
    if (!endsWith(osrm_server, "/")) {
        osrm_server <- paste0(osrm_server, "/", sep = "")
    }
    # Create tab with coordinates pair
    input_table <- paste0(osrm_server, "table/v1/", osrm_profile, "/")
    input_table <- paste0(input_table, paste(adjust_coord(loc$lon),
        adjust_coord(loc$lat),
        sep = ",", collapse = ";"
    ))
    return(input_table)
}

#' @title Adjust coordinates to fit within OSRM requirements
#' @keywords internal
#' @seealso \code{\link{osrmtable}}
adjust_coord <- function(coord) {
    format(round(as.numeric(coord), 5),
        scientific = FALSE, justify = "none",
        trim = TRUE, nsmall = 5, digits = 5
    )
}

#' @title Check OSRM's query limits and provide warnings.
#' @description This function is created in order to prevent the user
#' from composing queries that go over the `default` limits of the
#' OSRM servers.
#' @keywords internal
#' @seealso \code{\link{osrmtable}} for the main function
check_osrm_limits <- function(src, dst) {
    nrow_src <- nrow(sf::st_coordinates(src))
    nrow_dst <- nrow(sf::st_coordinates(dst))
    over_limit <- FALSE
    remote_warn <- simpleWarning("The public OSRM API does not allow
    results with a number of durations higher than 10000. Ask for fewer
    durations or use your own server and set the --max-table-size option to
    a value > 10000.")
    local_warn <- simpleWarning("This request might be too large for the default
    settings of the OSRM API to be processed in a single request. Please ignore
    warning, if you already modified the --max-table-size settings of the OSRM
    instance(s) to a number higher than the defeault 100.000. Otherwise, use
    this setting when setting up the OSRM instance(s).")
    # Find if local server or remote
    if (is.null(getOption("osrm.server"))) {
        if (nrow_src * nrow_dst > 10000) {
            over_limit <- TRUE
            stop(remote_warn)
        }
        invisible(over_limit)
    } else if (
        grepl("localhost", getOption("osrm.server"),
            fixed = TRUE
        ) & (nrow_src * nrow_dst) > 100000) {
        warning(local_warn, call. = FALSE)
        over_limit <- TRUE
    } else {
        invisible(over_limit)
    }
    invisible(over_limit)
}

#' @title Format OSRM output tables
#' @keywords internal
#' @seealso \code{\link{osrmtable}} for the main function
format_osrm_output_table <- function(out, features, type) {
    if (type == "durations") {
        out_matrix <- out$durations
        out_matrix <- round(out_matrix / (60), 1)
    } else if (type == "distances") {
        out_matrix <- out$distances
        out_matrix <- round(out_matrix, 0)
    } else {
        e <- simpleError("OSRM's output table type not recognized.\n
        Please check your OSRM server configuration.")
        stop(e)
    }
    dimnames(out_matrix) <- features$id
    return(out_matrix)
}

#' @title Format output coordinates table
#' @keywords internal
#' @seealso \code{\link{osrmtable}} for the main function
format_coord_table <- function(out, features, type) {
    if (type == "sources") {
        sources <- format_sources(out, features)
        return(sources)
    }
    if (type == "destinations") {
        destinations <- format_destinations(out, features)
        return(destinations)
    }
}

#' @keywords internal
#' @seealso \code{\link{format_coord_table}}
format_sources <- function(out, features) {
    return(data.frame(matrix(unlist(out$sources$location,
        use.names = T
    ),
    ncol = 2, byrow = T,
    dimnames = list(features$id, c("lon", "lat"))
    )))
}

#' @keywords internal
#' @seealso \code{\link{format_coord_table}}
format_destinations <- function(out, features) {
    return(data.frame(matrix(unlist(out$destinations$location,
        use.names = T
    ),
    ncol = 2, byrow = T,
    dimnames = list(features$id, c("lon", "lat"))
    )))
}