#' @importFrom magrittr %>%
#' @importFrom ggplot2 layer_scales ggplot aes geom_point ggplotGrob labs
#' @importFrom patchwork wrap_plots
#' @importFrom purrr transpose
#' @importFrom stringr str_detect
NULL

#' Get information about a list of plots
#'
#' This function extracts the number of plots, the number of layers across all plots, and the number of facets
#'
#' @param plot_lst A list of ggplot objects
#' @param verbose Controls verbosity of output details
#' @return A list with the number of plots, layers, facets, text, and annotations (e.g. p-value annotations from rstatix)
#' @export
get_plot_info <- function(plot_lst, verbose = FALSE) {
    num_plots <- length(plot_lst)
    num_layers <- sapply(plot_lst, function(p) length(p$layers))
    num_facets <- sapply(plot_lst, function(p) {
        ggplot_data_obj <- ggplot2::ggplot_build(p)$data[[1]]
        panel_levels_num <- max(as.numeric(levels(ggplot_data_obj$PANEL)))
        if (panel_levels_num == 1) {
            num_facets <- 0
        } else {
            num_facets <- max(panel_levels_num)
        }
    })

    num_annots <- sapply(plot_lst, function(p) {
        ggplot_data_obj <- ggplot2::ggplot_build(p)$data
        ann_bool <- sapply(ggplot_data_obj, FUN = function(df) {
            "annotation" %in% colnames(df)
        })
        sum(ann_bool)
    })

    num_text <- sapply(plot_lst, function(p) {
        grob <- ggplot2::ggplotGrob(p)
        keep_grobs <- sapply(grob$grobs, FUN = function(i) !startsWith(as.character(i), "zero"))
        my_grobs <- grob$grobs[keep_grobs]
        my_grobs_names <- unlist(purrr::transpose(my_grobs)$name)
        num_title <- sum(ifelse(stringr::str_detect(my_grobs_names, "plot.title"), 1, 0))
        num_subtitle <- sum(ifelse(stringr::str_detect(my_grobs_names, "plot.subtitle"), 1, 0))
        num_caption <- sum(ifelse(stringr::str_detect(my_grobs_names, "plot.caption"), 1, 0))
        num_xlab <- sum(ifelse(stringr::str_detect(my_grobs_names, "axis.title.x"), 1, 0))
        num_ylab <- sum(ifelse(stringr::str_detect(my_grobs_names, "axis.title.y"), 1, 0))
        result <- num_title + num_subtitle + num_caption + num_xlab + num_ylab
        return(result)
    })


    if (verbose) {
        message(sprintf(
            "\nFound:\nnum_plots = %d\nnum_layers = %d\nnum_facets = %d\nnum_text = %d\nnum_annots = %d\n",
            num_plots, num_layers, num_facets, num_text, num_annots
        ))
    }

    return(list(
        num_plots = num_plots, num_layers = num_layers,
        num_facets = num_facets, num_text = num_text,
        num_annots = num_annots
    ))
}


#' Get the number of items on the x and y axes of a ggplot object
#'
#' This function extracts the data from a ggplot object and counts the unique number of
#' values of the x and y variables
#'
#' @param plot_lst A list of ggplot objects
#'
#' @return A list with the length or range of the x and y axes
#' @export
get_axes_info <- function(plot_lst) {
    num_x_items <- sapply(plot_lst, function(p) {
        ggplot_data_obj <- ggplot2::ggplot_build(p)$data[[1]]
        x_items <- length(ggplot_data_obj[[1]])
    })
    num_y_items <- sapply(plot_lst, function(p) {
        ggplot_data_obj <- ggplot2::ggplot_build(p)$data[[1]]
        y_items <- length(ggplot_data_obj[[2]])
    })

    result <- list(
        num_x_items = num_x_items,
        num_y_items = num_y_items
    )
    return(result)
}


#' This function calculates the aspect ratio by considering the number of facets and the range of the x and y axes.
#'
#' This function first sets a base aspect ratio of 1.0.
#' It then adjusts this base ratio based on the number of facets
#' and the number of items on the x and y axes. If there are
#' multiple facets, the aspect ratio is increased, which makes
#' the plot wider. If there are more items on the x-axis than on
#' the y-axis, the aspect ratio is increased, which also makes the plot wider.
#'
#' Conversely, if there are more items on the y-axis than on the x-axis,
#' the aspect ratio is decreased, which makes the plot taller.
#'
#' @param plot_lst A list of ggplot objects
#' @param plot_info A list containing the plot information from ggplot_build
#' @param axes_info The maximum number of x and y elements in the list of plots
#'
#' @return The adjusted aspect ratio
#' @export
get_aspect_ratio <- function(plot_lst, plot_info, axes_info) {
    arb_vec <- sapply(seq_len(plot_info$num_plots), FUN = function(i) {
        # Set the base aspect ratio (should i expose this?)
        aspect_ratio_base <- 0.5
        num_facets_i <- plot_info$num_facets[i]
        num_x_i <- axes_info$num_x_items[i]
        num_y_i <- axes_info$num_y_items[i]
        # Adjust the aspect ratio based on the number of facets
        if (num_facets_i > 0) {
            aspect_ratio_base <- sqrt(aspect_ratio_base * num_facets_i)
        }

        # Adjust the aspect ratio based on the x and y axis elements.
        # To avoid division by zero, add a small constant to the denominator.
        aspect_ratio_base <- sqrt(aspect_ratio_base * num_x_i / (num_y_i + 1e-10))
    })

    # Return the adjusted aspect ratio
    return(arb_vec)
}



#' Calculate plot complexity
#'
#' This function calculates complexity of all the plots
#' based off of the number of layers, axes lengths, number of text elements,
#' and facets in the final plot
#'
#' @param plot_info The list of plot information as calculated by `get_plot_info()`
#' @param axes_info Axes info generated from `get_axes_info()`
#'
#' @return This function returns a vector of numbers representing the complexity of the plots
#' @export
get_plot_complexity <- function(plot_info, axes_info) {
    # Weights for the complexity factors
    weights <- list(
        num_layers = 0.75,
        num_facets = 1.5,
        num_x_items = 0.3,
        num_y_items = 0.3,
        num_text = 0.4,
        num_annots = 3
    )

    # Calculate the complexity score
    base_log <- 2.5
    complexity_score <- sapply(seq_len(plot_info$num_plots), FUN = function(i) {
        result <- weights$num_layers * log(1 + plot_info$num_layers[i], base_log) +
            weights$num_facets * log(1 + plot_info$num_facets[i], base_log) +
            weights$num_x_items * log(1 + axes_info$num_x_items[i], base_log) +
            weights$num_y_items * log(1 + axes_info$num_y_items[i], base_log) +
            weights$num_text * log(1 + plot_info$num_text[i], base_log) +
            weights$num_annots * log(1 + plot_info$num_annots[i], base_log)
        return(result)
    })


    return(complexity_score)
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
#' @param filename The file name of the image to be saved
#' @param ncol The number of columns for plots to be placed into in desired in the final image
#' @param verbose Controls verbosity of output details
#'
#' @return This function does not return a value. It saves the final plot as an image.
#' @export
auto_save_plot <- function(plot_lst, filename, ncol = 1, verbose = FALSE) {
    plot_info <- get_plot_info(plot_lst, verbose = verbose)
    axes_info <- get_axes_info(plot_lst)
    complexity_score <- get_plot_complexity(plot_info, axes_info)
    aspect_ratio <- get_aspect_ratio(plot_lst, plot_info, axes_info)

    widths <- complexity_score * aspect_ratio + log(complexity_score * aspect_ratio)
    heights <- complexity_score + log(complexity_score)

    # Save the plot
    if (verbose) {
        message(sprintf( # \nbase_size = %d\n
            "\nComplexity score = %.2f\naspect_ratio = %.2f\nwidths = %.2f\nheights = %.2f\n",
            complexity_score, aspect_ratio, widths, heights
        ))
    }

    # Use the 'patchwork' package to arrange the plots
    final_plot <- patchwork::wrap_plots(plot_lst,
        widths = widths,
        heights = heights,
        ncol = ncol
    )

    # Make the output directory of the file
    dir_to_make <- dirname(filename)
    if (dir_to_make != ".") {
        if (verbose) {
            message("\nMaking plot parent directory...")
        }
        dir.create(dir_to_make, showWarnings = FALSE, recursive = TRUE)
    }

    final_width <- sum(complexity_score * aspect_ratio) - sum(log(complexity_score * max(aspect_ratio))) - max(aspect_ratio)
    final_height <- sum(complexity_score) - sum(log(complexity_score))
    if (verbose) {
        message(sprintf( # \nbase_size = %d\n
            "\nFinal width = %.2f\nFinal height = %.2f",
            final_width, final_height
        ))
    }
    # Save the plot
    ggplot2::ggsave(
        plot = final_plot,
        filename = filename,
        width = final_width,
        height = final_height,
        dpi = 300
    )

    if (verbose) {
        message("Done!")
    }
}
