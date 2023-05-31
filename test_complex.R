rm(list = ls())
library(tidyverse)
library(rstatix)
library(ggprism)
library(GetoptLong)
library(ggpubr)
library(patchwork) # using version 1.1.2.9000
library(autoggsaveR)

# vehicle_line_color <- "#000000"
# vehicle_point_color <- "#4d4a4a"
# sorafenib_line_color <- "#f3c281"
# sorafenib_point_color <- "#e88f1a"

vehicle_line_color <- "#535252"
vehicle_point_color <- "#ffffff"

sorafenib_line_color <- "#535252"
sorafenib_point_color <- "#535252"

sor_dox_line_color <- "#9BB3D3" # #CCD7E9
sor_dox_point_color <- "#9BB3D3"

sor_lis_line_color <- "#B53530" # #E3938A
sor_lis_point_color <- "#B53530"


my_base_size <- 20
# make pairwise comparison similar to canine data for veh vs sorafenib
data <- read_rds(file.path("/Users/ncamarda/Library/CloudStorage/OneDrive-Tufts/phd/ws/telemetRy/output_dir/Combined Sorafenib Dox Lis Output/analysis_files-final/Combined Sorafenib Dox Lis-Systolic.rds")) %>%
    ungroup()

colnames(data)
data$final_grouping %>% unique()
data$last_group_short %>% unique()

#' @note make plottable data
#' @param data raw data from .rds analysis files
#' @param GROUP_TO_FILTER the group(s) to filter for, e.g. c("vehicle") or c("sorafenib", "sor + lis"), etc
#' @param start_day the start day of the phase to be plotted, e.g. 0 for sorafenib phase and 3 for anti-HTN phase
make_data <- function(data, GROUP_TO_FILTER = c("vehicle"), start_day = 0) {
    init <- data %>%
        group_by(ID) %>%
        # filter the days in the phase range
        filter(
            num_day %in% c(start_day:(start_day + 3)),
            last_group_short %in% GROUP_TO_FILTER
        ) %>%
        mutate(
            Baseline = first(mean_values),
            Last = last(mean_values),
            Max = max(mean_values, na.rm = TRUE)
        ) %>%
        # then select the value from first day 'baseline' and
        # the value that is the maximum difference
        filter(num_day == start_day | num_day == last(num_day)) %>%
        arrange(ID) %>%
        # establish the names of the x axis
        mutate(phase = factor(
            ifelse(num_day %in% start_day,
                "Baseline",
                # "Last"
                "Max"
            ),
            # levels = c("Baseline", "Last")
            levels = c("Baseline", "Max")
        )) %>%
        # this last step here to ensure that we don't get more than 1 max
        group_by(ID, phase, last_group_short) %>%
        summarize(mean_values = mean(mean_values, na.rm = TRUE), .groups = "keep")

    init_mean <- init %>%
        group_by(phase, last_group_short) %>%
        summarize(group_mean_value = mean(mean_values, na.rm = TRUE), .groups = "keep")

    return(list(init, init_mean))
}

#' @note make figure-quality line plot for the mouse data
#' @param dat data from make_data() function
#' @param min_y_val minimum y value for graph
#' @param max_y_val max y value fro graph
#' @param color_stat_bar whether to color the statistics bar with the group color
#' @param subtitle the subtitle of the graph
make_line_plot <- function(dat, dat_mean, min_y_val = 0, max_y_val = 150, color_stat_bar = TRUE, subtitle = "") {
    line_colors <- c(vehicle_line_color, sorafenib_line_color, sor_dox_line_color, sor_lis_line_color) %>%
        set_names(c("vehicle", "sorafenib", "sor + dox", "sor + lis"))
    point_colors <- c(vehicle_point_color, sorafenib_point_color, sor_dox_point_color, sor_lis_point_color) %>%
        set_names(c("vehicle", "sorafenib", "sor + dox", "sor + lis"))
    point_shapes <- c(21, 22, 23, 23) %>% # 16, 22, 23, 23
        set_names(c("vehicle", "sorafenib", "sor + dox", "sor + lis"))
    # my_theme <- theme_prism(base_size = my_base_size) +
    #     theme(
    #         plot.title = element_text(size = rel(2)),
    #         plot.subtitle = element_text(size = rel(1.75)),
    #         axis.text = element_text(size = rel(2)),
    #         axis.title.y = element_text(size = rel(2)),
    #         legend.text = element_text(size = rel(1.5)),
    #         legend.justification = "left",
    #         legend.margin = margin(0, 0, 0, 0),
    #         legend.box.margin = margin(0, 20, 0, -25, "pt"),
    #         plot.margin = margin(12.5, 25, 12.5, 25, "pt"),
    #         # axis.text.x = element_text(size = rel(1.5)), # , hjust = 1, vjust = 1), # angle = 45,
    #         strip.text.x = element_text(size = rel(3), face = "bold"),
    #         panel.grid.major = element_line(colour = "gray", linetype = 3, linewidth = rel(0.5)),
    #         panel.grid.minor = element_line(colour = "gray", linetype = 2, linewidth = rel(0.25)),
    #         aspect.ratio = 1,
    #         axis.line = element_line(linewidth = rel(2))
    #         # legend.position = "bottom"
    #     )

    # line_width_size1 <- rel(2) # rel(1.075)
    # line_width_size2 <- rel(3.5) # rel(1.5)
    # point_size <- rel(7.5) # rel(3)
    # p_val_size <- rel(14) # rel(8)

    paired_ttest <- dat %>%
        group_by(last_group_short) %>%
        pairwise_t_test(mean_values ~ phase, paired = TRUE) %>%
        add_y_position(fun = "max") %>%
        ungroup() %>%
        mutate(
            rn = row_number(),
            y.position = min(y.position) + rn * 2.5
        )
    paired_ttest

    plot <- ggplot(
        data = dat_mean,
        aes(
            x = phase, y = group_mean_value, color = last_group_short,
            shape = last_group_short, fill = last_group_short
        )
    ) +
        scale_shape_manual(values = point_shapes) +
        scale_color_manual(values = line_colors) +
        scale_fill_manual(values = point_colors) +
        geom_line(dat,
            mapping = aes(
                x = phase, y = mean_values, color = last_group_short,
                group = ID
            ),
            # linewidth = line_width_size1,
            alpha = 0.3,
            show.legend = FALSE
        ) +
        geom_point(dat,
            mapping = aes(
                x = phase, y = mean_values,
                fill = last_group_short,
                shape = last_group_short,
            ),
            color = "black", # set the outline color of the points
            # size = point_size,
            alpha = 0.3,
            # stroke = NA, # this removes the outlien
            show.legend = FALSE # to remove the border around the point
            # inherit.aes = FALSE
            # width = 0.1
        ) +
        geom_line(dat_mean,
            mapping = aes(
                x = phase, y = group_mean_value,
                color = last_group_short,
                group = last_group_short
            ),
            linewidth = rel(1.1),
            linetype = 1,
            inherit.aes = FALSE,
            show.legend = FALSE
        ) +
        stat_summary(dat_mean,
            mapping = aes(
                x = phase, y = group_mean_value,
                fill = last_group_short,
                shape = last_group_short
            ),
            fun = mean, # compute the mean value
            geom = "point", # use points to represent the mean
            size = rel(2), # set the size of the points
            color = "black", # set the outline color of the points
            inherit.aes = FALSE,
            show.legend = TRUE,
        ) +
        scale_y_continuous(limits = c(
            min_y_val - 5,
            max_y_val + 10
        ), expand = c(0, 0)) +
        # my_theme +
        # guides(shape = guide_legend(nrow = 2)) +
        labs(
            title = "Example Data",
            x = "",
            # x = "Baseline vs Maximum BP Measurement",
            y = "mmHg",
            subtitle = subtitle
            # caption = qq("Paired two-tailed t-tests\nBaseline vehicle vs vehicle: p=@{round(paired_ttest$p.adj[1], 4)}\nBaseline sorafenib vs sorafenib: p=@{round(paired_ttest$p.adj[2], 4)}")
        ) +
        scale_x_discrete(expand = c(0.25, 0.25)) # controls the margins
    if (color_stat_bar) {
        plot <- plot +
            stat_pvalue_manual(
                paired_ttest,
                color = "last_group_short",
                show.legend = FALSE,
                # label.size = p_val_size, # rel(5)
                # bracket.size = 1,
                hide.ns = TRUE,
                label = "{p.adj.signif}" # "p = {round(p.adj, 6)}"
            )
    } else {
        plot <- plot +
            stat_pvalue_manual(
                paired_ttest,
                show.legend = FALSE,
                # label.size = p_val_size, # rel(5)
                # bracket.size = 1,
                hide.ns = TRUE,
                label = "{p.adj.signif}" # "p = {round(p.adj, 6)}"
            )
    }
    plot
}


my_min <- function(x) min(x, na.rm = TRUE)
my_max <- function(x) max(x, na.rm = TRUE)


# first sorafenib to determine max vals
sor_lst <- make_data(data, c("sorafenib", "sor + dox", "sor + lis"), start_day = 0)
sor_init <- sor_lst[[1]]
sor_init_mean <- sor_lst[[2]]

sort_init_mean_min <- my_min(sor_init$mean_values)
sort_init_mean_max <- my_max(sor_init$mean_values)

sor_htn_lst <- make_data(data, c("sorafenib", "sor + dox", "sor + lis"), start_day = 3)
sor_htn_phase <- sor_htn_lst[[1]]
sor_htn_mean <- sor_htn_lst[[2]]

sor_htn_phase_mean_min <- my_min(sor_htn_phase$mean_values)
sor_htn_phase_mean_max <- my_max(sor_htn_phase$mean_values)

sor_pre_plot <- make_line_plot(
    dat = sor_init, dat_mean = sor_init_mean,
    min_y_val = sort_init_mean_min,
    max_y_val = sort_init_mean_max,
    subtitle = "Example 2"
)
sor_pre_plot
sor_post_plot <- make_line_plot(
    dat = sor_htn_phase, dat_mean = sor_htn_mean,
    min_y_val = sor_htn_phase_mean_min,
    max_y_val = sor_htn_phase_mean_max,
    subtitle = "Example 4"
)
sor_post_plot


veh_lst <- make_data(data, c("vehicle"), start_day = 0)
veh_init <- veh_lst[[1]]
veh_init_mean <- veh_lst[[2]]

veh_htn_lst <- make_data(data, c("vehicle"), start_day = 3)
veh_htn_phase <- veh_htn_lst[[1]]
veh_htn_mean <- veh_htn_lst[[2]]

veh_pre_plot <- make_line_plot(
    dat = veh_init, dat_mean = veh_init_mean,
    min_y_val = sort_init_mean_min,
    max_y_val = sort_init_mean_max,
    subtitle = "Example 1"
)
veh_pre_plot
veh_post_plot <- make_line_plot(
    dat = veh_htn_phase, dat_mean = veh_htn_mean,
    min_y_val = sor_htn_phase_mean_min,
    max_y_val = sor_htn_phase_mean_max,
    subtitle = "Example 3"
)
veh_post_plot

final_plot <- (veh_pre_plot | sor_pre_plot) / (veh_post_plot | sor_post_plot)
final_plot
ggsave(
    plot = final_plot,
    filename = file.path("example_images/GGSAVE_complex.pdf"),
    width = 25,
    height = 25
)

final_plot_lst <- list(veh_pre_plot, sor_pre_plot, veh_post_plot, sor_post_plot)
auto_save_plot(
    plot_lst = final_plot_lst,
    filename = "example_images/AUTOPLOT_complex.pdf",
    ncol = 2
)
