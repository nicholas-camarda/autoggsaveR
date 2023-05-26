#' @importFrom magrittr %>%
#' @importFrom ggplot2 layer_scales
NULL

#' Get information about a list of plots
#'
#' This function extracts the number of plots, the number of layers across all plots, and the number of facets
#'
#' @param plot_lst A list of ggplot objects
#'
#' @return A list with the number of plots, layers, and facets
get_plot_info <- function(plot_lst) {
    num_plots <- length(plot_lst)
    num_layers <- sum(sapply(plot_lst, function(p) length(p$layers)))
    num_facets <- sum(sapply(plot_lst, function(p) length(levels(ggplot2::ggplot_build(p)$data[[1]]$PANEL))))

    message(GetoptLong::qq("Found:
        num_plots = @{num_plots}
        num_layers = @{num_layers}
        num_facets = @{num_facets}"))

    return(list(num_plots = num_plots, num_layers = num_layers, num_facets = num_facets))
}


#' Get the number of items on the x and y axes of a ggplot object
#'
#' This function extracts the data from a ggplot object and counts the unique
#' values of the x and y variables if it's discrete, or calculates the range if it's continuous.
#' It also calculates the range of the y variable.
#'
#' @param plot A ggplot object
#'
#' @return A list with the length or range of the x and y axes, depending on whether they are continuous or discrete
get_num_plot_items <- function(plot) {
    # Extract the data from the plot
    plot_data <- ggplot2::ggplot_build(plot)$data[[1]]

    # Check if x-axis is discrete or continuous by checking the class of the scale
    x_discrete <- inherits(layer_scales(plot)$x, "ScaleDiscrete")

    # Count the unique values of the x variable if it's discrete, or calculate the range if it's continuous
    num_x_items <- if (x_discrete) {
        num_x_items <- length(unique(plot_data$x))
    } else {
        x_range <- layer_scales(plot)$x$get_limits()
        num_x_items <- x_range[2] - x_range[1]
    }

    # Check if y-axis is discrete or continuous by checking the class of the scale
    y_discrete <- inherits(layer_scales(plot)$y, "ScaleDiscrete")

    # Count the unique values of the x variable if it's discrete, or calculate the range if it's continuous
    num_x_items <- if (y_discrete) {
        num_y_items <- length(unique(plot_data$y))
    } else {
        y_range <- ggplot2::layer_scales(plot)$y$get_limits()
        num_y_items <- y_range[2] - y_range[1]
    }
    return(list(num_x_items = num_x_items, num_y_items = num_y_items))
}


#' Automatically save a list of ggplot objects as a single image
#'
#' This function takes a list of ggplot objects, combines them into a single
#' patchwork plot, calculates the optimal dimensions for the final plot based on
#' the number of plots, layers, facets, and the maximum number of items on the x
#' and y axes, and saves the final plot as an image.
#'
#' Supports multiple plots in a single ggplot2 object as created by `library(patchwork)`
#'
#' @param plot_lst A list of ggplot objects
#' @param file_path The path where the image should be saved
#' @param ncol The number of columns in the final plot (default is 1)
#' @param base_size The base size for the final plot (default is 20)
#'
#' @return This function does not return a value. It saves the final plot as an image.
auto_save_plot <- function(plot_lst, file_path, ncol = 1, base_size = 20) {
    # Get the plot info
    plot_info <- get_plot_info(plot_lst)
    axes_info <- t(sapply(plot_lst, function(p) get_num_plot_items(p))) %>%
        tidyr::as_tibble() %>%
        tidyr::unnest(cols = c("num_x", "num_y"))
    max_num_x <- max(axes_info$num_x, na.rm = TRUE)
    max_num_y <- max(axes_info$num_y, na.rm = TRUE)

    # Adjust the base size based on the inverse of the number of plots
    log_attrb <- log(plot_info$num_plots + plot_info$num_layers + plot_info$num_facets + ncol)
    adjusted_base_size <- sqrt(base_size - plot_info$num_plots + 1) * log_attrb
    message(GetoptLong::qq("Adjusted base size = @{adjusted_base_size}"))

    # Adjust the text size of each plot in the list
    indv_adjusted_base_size <- adjusted_base_size + 2
    message(GetoptLong::qq("Applying slightly increased base size to individual plots:  @{indv_adjusted_base_size}"))
    plot_lst <- lapply(plot_lst, function(p) p + ggplot2::theme(text = ggplot2::element_text(size = indv_adjusted_base_size)))

    # Combine the plots into a patchwork object
    final_plot <- patchwork::wrap_plots(plotlist = plot_lst, ncol = ncol)

    # Calculate dimensions based on the number of axes lengths, panels, plots, and facets in the plot
    # Normalize the y-range by the maximum y-range
    normalized_y_range <- max_num_y / max(axes_info$num_y, na.rm = TRUE)
    height <- adjusted_base_size - normalized_y_range + log(plot_info$num_layers + plot_info$num_plots + plot_info$num_facets + ncol) * 2
    width <- adjusted_base_size + log(max_num_x) + log(plot_info$num_layers + plot_info$num_plots + plot_info$num_facets + ncol) * 2

    message(paste("Plotting with height =", height, "and width =", width, "\n"))

    # Save the plot with the calculated dimensions
    ggplot2::ggsave(file_path, plot = final_plot, height = height, width = width)
}
