# autoggsaveR

`autoggsaveR` is an R package that provides functions to automatically save a list of ggplot objects as a single image. It calculates the optimal dimensions for the final plot based on the number of plots, layers, facets, and the maximum number of items on the x and y axes.

## Installation

You can install the `autoggsaveR` package from GitHub using `devtools`:

```r
install.packages("devtools")
devtools::install_github("nicholas-camarda/autoggsaveR")
```

## Usage

Introduction
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

Finally, you can save the plots as a single image using the auto_save_plot function. This will save the plots as a single image in a directory you specify relative to your working directory:
```r
auto_save_plot(plot_lst, "my_plot.png")
```
