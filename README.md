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
p1 <- ggplot(mtcars, aes(mpg, disp)) +
  geom_point()
p2 <- ggplot(mtcars, aes(hp, wt)) +
  geom_point()
plot_lst <- list(p1, p2)
```

You can get information about the plots using the `get_plot_info` function:

```r
plot_info <- get_plot_info(plot_lst)
print(plot_info)
```

You can also get the number of items on the x and y axes of a plot using the `get_num_plot_items` function:

```r
axes_info <- get_num_plot_items(p1)
print(axes_info)
```

Finally, you can save the plots as a single image using the auto_save_plot function. This will save the plots as a single image in a directory you specify relative to your working directory. The output directory will be created recursively if it doesn't exist:

```r
auto_save_plot(plot_lst, "my_plot.png")
```

## Example plot

```r
p1 <- ggplot2::ggplot(mtcars, ggplot2::aes(hp, wt, color = as.factor(cyl))) +
    ggplot2::geom_point() +
    ggplot2::facet_wrap(~`cyl`) +
    ggplot2::theme_bw(base_size = 20) +
    ggplot2::labs(title = "My Title", 
                  subtitle = "subtitle", 
                  caption = "caption")
```

With autoggsaveR:

```r
ggplot2::ggsave(
    plot = p1,
    filename = "example_images/test-no_auto.png"
)
#  Saving 13.9 x 10.2 in image
```

Without autoggsaveR:

```r
auto_save_plot(
    plot = list(p1), 
    relative_output_dir = "example_images", 
    file_name = "test_withauto.png", 
    base_size = 20, 
    ncol = 1,
    verbose = TRUE
)
# Found:
#             num_plots = 1
#             num_layers = 1
#             num_facets = 3
# Adjusted base size = 8.01299194504575
# Applying slightly increased base size to individual plots:  10.0129919450457
# Plotting with height = 8.22921505351538 and width = 14.6875533368602 
```
