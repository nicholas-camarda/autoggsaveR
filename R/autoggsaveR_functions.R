#' @importFrom magrittr %>%
#' @importFrom ggplot2 layer_scales ggplot aes geom_point
#' @importFrom patchwork wrap_plots
NULL

#' Get information about a list of plots
#'
#' This function extracts the number of plots, the number of layers across all plots, and the number of facets
#'
#' @param plot_lst A list of ggplot objects
#'
#' @return A list with the number of plots, layers, and facets
get_plot_info <- function(plot_lst, verbose = FALSE) {
    num_plots <- length(plot_lst)
    num_layers <- sum(sapply(plot_lst, function(p) length(p$layers)))
    num_facets <- sum(sapply(plot_lst, function(p) {
        ggplot_data_obj <- ggplot2::ggplot_build(p)$data[[1]]
        # if no faceting, panel = 1
        panel_levels_num <- max(as.numeric(levels(ggplot_data_obj$PANEL)))
        if (panel_levels_num == 1) {
            num_facets <- 0
        } else {
            num_facets <- max(panel_levels_num)
        }
    }))

    if (verbose) {
        message(GetoptLong::qq("Found:
            num_plots = @{num_plots}
            num_layers = @{num_layers}
            num_facets = @{num_facets}"))
    }


    return(list(num_plots = num_plots, num_layers = num_layers, num_facets = num_facets))
}


#' Get the number of items on the x and y axes of a ggplot object
#'
#' This function extracts the data from a ggplot object and counts the unique number of
#' values of the x and y variables
#'
#' @param plot A ggplot object
#'
#' @return A list with the length or range of the x and y axes
get_num_plot_items <- function(plot) {
    # Extract the data from the plot
    plot_data <- ggplot2::ggplot_build(plot)$data[[1]]
    num_x_items <- length(unique(plot_data$x))

    # Count the unique values of the x variable if it's discrete, or calculate the range if it's continuous
    # num_y_items <- if (y_discrete) {
    num_y_items <- length(unique(plot_data$y))
    # } else {
    # y_range <- ggplot2::layer_scales(plot)$y$get_limits()
    # num_y_items <- y_range[2] - y_range[1]
    # }
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
#' @param verbose Controls verbosity of output details
#'
#' @return This function does not return a value. It saves the final plot as an image.
auto_save_plot <- function(plot_lst, file_path, ncol = 1, base_size = 20, verbose = TRUE) {
    # Get the plot info
    plot_info <- get_plot_info(plot_lst, verbose = verbose)
    axes_info <- t(sapply(plot_lst, function(p) get_num_plot_items(p))) %>%
        tidyr::as_tibble() %>%
        tidyr::unnest(cols = c(`num_x_items`, `num_y_items`))
    max_num_x <- max(axes_info$num_x_items, na.rm = TRUE)
    max_num_y <- max(axes_info$num_y_items, na.rm = TRUE)

    # Adjust the base size based on the inverse of the number of plots
    log_attrb <- log(plot_info$num_plots + plot_info$num_layers + plot_info$num_facets + ncol)
    adjusted_base_size <- sqrt(base_size - plot_info$num_plots + 1) * log_attrb

    # Adjust the text size of each plot in the list
    indv_adjusted_base_size <- adjusted_base_size + 2
    plot_lst <- lapply(plot_lst, function(p) {
        p + ggplot2::theme(
            text = ggplot2::element_text(size = indv_adjusted_base_size),
            plot.margin = ggplot2::margin(0.1, 0.1, 0.1, 0.1, "cm")
        )
    })

    # Combine the plots into a patchwork object
    final_plot <- patchwork::wrap_plots(plotlist = plot_lst, ncol = ncol)

    # Calculate dimensions based on the number of axes lengths, panels, plots, and facets in the plot
    # Normalize the y-range by the maximum y-range
    height <- adjusted_base_size - log(max_num_y) + log(plot_info$num_layers + plot_info$num_plots + plot_info$num_facets + ncol) * 2
    width <- adjusted_base_size + log(max_num_x) + log(plot_info$num_layers + plot_info$num_plots + plot_info$num_facets + ncol) * 2

    if (verbose) {
        message(GetoptLong::qq("Adjusted base size = @{adjusted_base_size}"))
        message(GetoptLong::qq("Applying slightly increased base size to individual plots:  @{indv_adjusted_base_size}"))
        message(paste("Plotting with height =", height, "and width =", width, "\n"))
    }

    # Save the plot with the calculated dimensions
    ggplot2::ggsave(file_path, plot = final_plot, height = height, width = width)
}
