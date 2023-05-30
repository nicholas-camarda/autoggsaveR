#' @importFrom magrittr %>%
#' @importFrom ggplot2 layer_scales ggplot aes geom_point
#' @importFrom patchwork wrap_plots
NULL

#' Get information about a list of plots
#'
#' This function extracts the number of plots, the number of layers across all plots, and the number of facets
#'
#' @param plot_lst A list of ggplot objects
#' @param verbose Controls verbosity of output details
#' @return A list with the number of plots, layers, and facets
#' @export
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
#' @export
get_num_plot_items <- function(plot) {
    # Extract the data from the plot
    plot_data <- ggplot2::ggplot_build(plot)$data[[1]]
    num_x_items <- length(unique(plot_data$x))

    # Count the unique values of the x variable
    num_y_items <- length(unique(plot_data$y))
    return(list(num_x_items = num_x_items, num_y_items = num_y_items))
}

#' Calculate plot complexity
#'
#' This function calculates complexity of the final plot
#' based off of the number of plots, layers, and facets, and the
#' desired number of columns of plots, in the final plot
#'
#' @param base_size The base size for the final plot (default is 20)
#' @param plot_info The list of plot information as calculated by `get_plot_info`
#' @param ncol The number of columns in the output
#'
#' @return This function returns a number representing the complexity of the plot
#' @export
get_plot_complexity <- function(base_size = 20, plot_info, ncol) {
    sqrt_attrb <- log(plot_info$num_plots + plot_info$num_layers + plot_info$num_facets + ncol)
    p_cmplx <- sqrt(base_size - plot_info$num_plots + 1) * sqrt_attrb
    return(p_cmplx)
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
#' @param relative_output_dir relative output directory for the image to be saved
#' @param file_name The file name of the image to be saved
#' @param ncol The number of columns in the final plot (default is 1)
#' @param base_size The base size for the final plot (default is 20)
#' @param verbose Controls verbosity of output details
#'
#' @return This function does not return a value. It saves the final plot as an image.
#' @export
auto_save_plot <- function(plot_lst, relative_output_dir, file_name, ncol = 1, base_size = 20, verbose = TRUE) {
    # Get the plot info
    plot_info <- get_plot_info(plot_lst, verbose = verbose)
    axes_info <- t(sapply(plot_lst, function(p) get_num_plot_items(p))) %>%
        tidyr::as_tibble() %>%
        tidyr::unnest(cols = c(`num_x_items`, `num_y_items`))
    max_num_x <- max(axes_info$num_x_items, na.rm = TRUE)
    max_num_y <- max(axes_info$num_y_items, na.rm = TRUE)

    # Adjust the base size
    adjusted_base_size <- get_plot_complexity(base_size = base_size, plot_info = plot_info, ncol = ncol)
    complexity_ratio <- base_size / adjusted_base_size

    # Adjust the text size of each plot in the list
    if (verbose) {
        message("For individual plots:")
    }
    plot_lst_updated <- lapply(plot_lst, function(p) {
        # Get the complexity of the individual plot
        indv_plot_info <- get_plot_info(list(p), verbose = verbose)
        indv_adjusted_base_size <- get_plot_complexity(base_size = base_size, plot_info = indv_plot_info, ncol = ncol)
        indv_complexity_ratio <- indv_adjusted_base_size / adjusted_base_size

        # Adjust the text
        p1 <- p + ggplot2::theme(
            plot.margin = ggplot2::margin(0.25, 0.25, 0.25, 0.25, "cm"),
            text = ggplot2::element_text(size = base_size * indv_complexity_ratio),
            axis.title = ggplot2::element_text(size = base_size * indv_complexity_ratio),
            axis.ticks = ggplot2::element_line(linewidth = base_size * indv_complexity_ratio * 0.05),
            axis.ticks.length = ggplot2::unit(base_size * indv_complexity_ratio * 0.2, "pt"),
            axis.text = ggplot2::element_text(size = base_size * indv_complexity_ratio * 0.8),
            plot.title = ggplot2::element_text(size = base_size * indv_complexity_ratio * 1.2),
            plot.subtitle = ggplot2::element_text(size = base_size * indv_complexity_ratio),
            strip.text = ggplot2::element_text(size = base_size * indv_complexity_ratio)
        )

        # Check if the plot has geom_point or geom_line and adjust accordingly
        for (layer in p$layers) {
            if (class(layer$geom)[1] == "GeomPoint") {
                p2 <- p1 + ggplot2::geom_point(size = base_size * indv_complexity_ratio * 0.125)
            }
            if (class(layer$geom)[1] == "GeomLine") {
                p2 <- p1 + ggplot2::geom_line(linewidth = base_size * indv_complexity_ratio * 0.05)
            }
        }

        return(p2)
    })

    # Combine the plots into a patchwork object
    final_plot <- patchwork::wrap_plots(plotlist = plot_lst_updated, ncol = ncol)

    # Calculate dimensions based on the number of axes lengths, panels, plots, and facets in the plot
    # Normalize the y-range by the maximum y-range
    height <- adjusted_base_size - log(max_num_y) + log(plot_info$num_layers + plot_info$num_plots + plot_info$num_facets + ncol)
    width <- adjusted_base_size - log(max_num_x) + log(plot_info$num_layers + plot_info$num_plots + plot_info$num_facets + ncol)

    if (verbose) {
        message(GetoptLong::qq("Adjusted base size = @{adjusted_base_size}"))
        # message(GetoptLong::qq("Applying adjusted base size to height/width calculation:  @{indv_adjusted_base_size}"))
        message(paste("Plotting with height =", height, "and width =", width, "\n"))
    }

    dir.create(relative_output_dir, showWarnings = FALSE, recursive = TRUE)
    # Save the plot with the calculated dimensions
    ggplot2::ggsave(
        filename = file.path(relative_output_dir, file_name),
        plot = final_plot, height = height, width = width
    )
}
