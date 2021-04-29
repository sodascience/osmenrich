#' Nests count of common swifts in Utrecht.
#'
#' An sf dataset containing 99 nests count of common swifts in the
#' municipality of Utrecht (The Netherlands) and their geographical position.
#' As the dataset is formatted as a simple feature collection it also contains
#' attributes such as the geometry_type, dimension, bbox and CRS.
#'
#' @format A data frame with 99 rows and 2 variables:
#' \describe{
#'   \item{nest_count}{number of nests in one position}
#'   \item{geometry}{the geographical position of the nests}
#'   ...
#' }
#' @source \url{https://ckan.dataplatform.nl/dataset/gierzwaluwinventarisatie-2014}
"common_swift"
