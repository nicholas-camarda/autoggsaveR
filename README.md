# autoggsaveR

`autoggsaveR` is an R package that provides functions to automatically save a list of ggplot objects as a single image. It calculates the optimal dimensions for the final plot based on the number of plots, layers, facets, and the maximum number of items on the x and y axes.

## Installation

You can install the `autoggsaveR` package from GitHub using `devtools`:

```r
install.packages("devtools")
devtools::install_github("nicholas-camarda/autoggsaveR")
```

## Usage

```r
# Load the package
library(autoggsaveR)

# Create a list of plots
  p1 <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, disp, color = wt)) +
    ggplot2::geom_point() +
    ggplot2::scale_colour_steps2(
      low = "blue",
      mid = "white",
      high = "red",
    ) +
    ggplot2::facet_wrap(~`cyl`) +
    ggplot2::labs(title = "plot 1", subtitle = "subtitle 1")

  p2 <- ggplot2::ggplot(mtcars, ggplot2::aes(hp, wt)) +
    ggplot2::geom_point() +
    ggplot2::geom_label(ggplot2::aes(label = wt)) + # 2 layers here
    ggplot2::facet_wrap(~`gear`) +
    ggplot2::labs(title = "plot 2", subtitle = "subtitle 2")

  p3 <- ggplot2::ggplot(mtcars, ggplot2::aes(factor(cyl), qsec, fill = factor(cyl))) +
    ggplot2::geom_boxplot() +
    ggplot2::labs(
      title = "plot 3",
      subtitle = "subtitle 3",
      caption = "caption" # add a caption
    ) +
    ggpubr::stat_compare_means(
      label.x.npc = "middle",
      ggplot2::aes(label = ggplot2::after_stat(p.signif)),
      method = "t.test", ref.group = "4",
      comparisons = list(c("4", "6"), c("4", "8"), c("6", "8")),
      label.y = c(23, 22, 21)
    )
  plot_lst <- list(p1, p2, p3)
```

You can get information about the plots using the `get_plot_info` function:

```r
plot_info <- get_plot_info(plot_lst)
   print(plot_info)
# $num_plots
# [1] 3

# $num_layers
# [1] 1 2 2

# $num_facets
# [1] 3 3 0

# $num_text
# [1] 4 4 5

# $num_annots
# [1] 0 0 1
```

You can also get the number of items on the x and y axes of the plots using the `get_num_plot_items` function:

```r
axes_info <- get_axes_info(plot_lst)
print(axes_info)

# $num_x_items
# [1] 32 32 3

# $num_y_items
# [1] 32 32 3
```

Finally, you can save the plots as a single image using the auto_save_plot function. This will save the plots as a single image in a directory you specify relative to your working directory. The output directory will be created recursively if it doesn't exist:

```r
auto_save_plot(
    plot = plot_lst, 
    filename = "example_images/test_withauto.png", 
    ncol = 1,
    verbose = TRUE
)
```

## Example plot

Without `autoggsaveR`:

```r
library(patchwork)
ggplot2::ggsave(plot = p1 + p2 + p3, filename = file.path("example_images", "test-no_auto.png"))

# Saving 6.74 x 6.86 in image
```

![alt text](example_images/test-no_auto.png)

With `autoggsaveR`, the dimensions are more appealing:

```r
library(autoggsaveR)
auto_save_plot(
    plot = plot_lst, 
    filename = "example_images/test_withauto.png", 
    ncol = 3,
    verbose = TRUE
)

# Found:
# num_plots = 3
# num_layers = 1
# num_facets = 3
# num_text = 4
# num_annots = 0

# Found:
# num_plots = 3
# num_layers = 2
# num_facets = 3
# num_text = 4
# num_annots = 0

# Found:
# num_plots = 3
# num_layers = 2
# num_facets = 0
# num_text = 5
# num_annots = 1


# Complexity score = 7.71
# aspect_ratio = 1.11
# widths = 10.67
# heights = 9.75

# Complexity score = 8.04
# aspect_ratio = 1.11
# widths = 11.08
# heights = 10.12

# Complexity score = 5.85
# aspect_ratio = 0.71
# widths = 5.56
# heights = 7.62


# Final width = 14.26
# Final height = 15.71
```

![alt text](example_images/test_withauto.png)
