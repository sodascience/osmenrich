% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/distance_funs.R
\name{measure_funs}
\alias{measure_funs}
\alias{duration_by_foot}
\alias{distance_by_foot}
\alias{duration_by_car}
\alias{distance_by_car}
\alias{duration_by_bike}
\alias{distance_by_bike}
\alias{osrm_distance}
\alias{osrm_duration}
\title{Compute distance and duration measures matrix using the OSRM server.}
\usage{
duration_by_foot(src, dst)

distance_by_foot(src, dst)

duration_by_car(src, dst)

distance_by_car(src, dst)

duration_by_bike(src, dst)

distance_by_bike(src, dst)

osrm_distance(src, dst, profile)

osrm_duration(src, dst, profile)
}
\arguments{
\item{src}{\code{sfc} object with the source points.}

\item{dst}{\code{sfc} object with the destination points.}

\item{profile}{\code{character} \code{str} object indicating the OSRM profile needed.}
}
\value{
\code{matrix} Matrix with measures (distances or durations)
from src (rows) to dst (cols).
}
\description{
Uses an OSRM (open source routing machine) instance to compute distance
measures between source geometry and destination geometry. Measures
available are those enabled by the OSRM API service: walking, driving and
cycling. These measures are available in the following metrics:
duration (in minutes) and distance (in meters).
}
\seealso{
\code{\link[=enrich_opq]{enrich_opq()}}, \code{\link[=osrm_table]{osrm_table()}}
}
\concept{Functions to measure distance and duration.}
