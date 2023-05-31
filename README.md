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
p1 <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, disp)) +
  ggplot2::geom_point() +
  ggplot2::facet_wrap(~`cyl`)
p2 <- ggplot2::ggplot(mtcars, ggplot2::aes(hp, wt)) +
  ggplot2::geom_point() +
  ggplot2::facet_wrap(~`gear`)
p3 <- ggplot2::ggplot(mtcars, ggplot2::aes(drat, qsec)) +
  ggplot2::geom_point() +
  ggplot2::facet_wrap(~`carb`)
plot_lst <- list(p1, p2, p3)
```

You can get information about the plots using the `get_plot_info` function:

```r
plot_info <- get_plot_info(plot_lst)
print(plot_info)

# $num_plots
# [1] 3

# $num_layers
# [1] 1 1 1 

# $num_facets
# [1] 3 3 6

# $num_text
# [1] 2 2 2

# $num_annots
# [1] 0 0 0 0


```

You can also get the number of items on the x and y axes of the plots using the `get_num_plot_items` function:

```r
axes_info <- get_axes_info(plot_lst)
print(axes_info)

# $num_x_items
# [1] 32 32 32

# $num_y_items
# [1] 32 32 32
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
ggsave(plot = p1 + p2 + p3, filename = file.path("example_images", "test-no_auto.png"))

# Saving 6.64 x 4.78 in image
```

![alt text](example_images/test-no_auto.png)

With `autoggsaveR`, the dimensions are more appealing:

```r
library(autoggsaveR)
auto_save_plot(
    plot = plot_lst, 
    filename = "example_images/test_withauto.png", 
    ncol = 1,
    verbose = TRUE
)
# Found:
# num_plots = 3
# num_layers = 1
# num_facets = 3
# num_text = 2
# num_annots = 0

# Found:
# num_plots = 3
# num_layers = 1
# num_facets = 3
# num_text = 2
# num_annots = 0

# Found:
# num_plots = 3
# num_layers = 1
# num_facets = 6
# num_text = 2
# num_annots = 0

# Complexity score = 4.53
# aspect_ratio = 1.32
# widths = 5.97
# heights = 4.53

# Complexity score = 4.53
# aspect_ratio = 1.32
# widths = 5.97
# heights = 4.53

# Complexity score = 5.45
# aspect_ratio = 1.57
# widths = 8.53
# heights = 5.45

# Making plot parent directory...
# Final width = 12.84
# Final height = 9.80
# Done!
```

![alt text](example_images/test_withauto.png)
