# Vectorized kernel implementations
# in general, at 0 distance, these return a value of 1, and the value
# decreases as the distance increases, reaching 0 at the limit of the support

#' @title Kernels used in summarizing features
#'
#' @description Kernels convert distance/ duration vectors to single numbers,
#'   with a certain weight for certain distances. In general, at 0 distance,
#'   these return a value of 1, and the value decreases as the distance
#'   increases, reaching 0 at the limit of the support.
#'
#' @param d The vector of distances/ durations.
#' @param r The radius of interest for the kernel to aggregate data.
#' @param reduce_fun The reduce function used to aggregate data.
#'
#' @details Gaussian kernel is a truncated gaussian, where r = 4*sigma
#'   (i.e., std. dev = r/4).The density which is truncated away is
#'   1 - erf(2 sqrt(2)), which is approximately 0.0000633.
#'   Parabola kernel is parabolic, decreasing with distance within
#'   radius r, and returns 0 elsewhere. It is a scaled Epanechnikov kernel.
#'   Uniform kernel returns 1 within radius r, 0 elsewhere.
#'
#' @return numeric, function (usually sum) of kernel-weighted distances or
#'   durations
#'
#' @name kernels
#' @export
#' @seealso [enrich_opq()]

#' @rdname kernels
#' @export
kernel_gaussian <- function(d, r = 100, reduce_fun = sum) {
    reduce_fun(
        4 / (r * sqrt(2 * pi)) * exp(-(4 * d / r)^2 / 2) * I(abs(d) <= r)
    )
}

#' @rdname kernels
#' @export
kernel_parabola <- function(d, r = 100, reduce_fun = sum) {
    reduce_fun(pmax(0, (1 - (d / r)^2)))
}

#' @rdname kernels
#' @export
kernel_uniform <- function(d, r = 100, reduce_fun = sum) {
    reduce_fun(abs(d) <= r)
}

class(kernel_gaussian) <- c("kernel", "function")
class(kernel_parabola) <- c("kernel", "function")
class(kernel_uniform) <- c("kernel", "function")
