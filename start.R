library(usethis)
library(devtools)
library(tidyverse)

usethis::use_r("autoggsaveR_functions")

usethis::use_package("ggplot2")
usethis::use_package("patchwork")
usethis::use_package("tidyr")
usethis::use_package("GetoptLong")
usethis::use_package("magrittr")
usethis::use_package("dplyr")

# add import statements as needed

usethis::use_mit_license("Nicholas Camarda")

usethis::use_git_remote("origin", url = NULL, overwrite = TRUE)

devtools::check()
# fix any errors

devtools::build()

# add tests
usethis::use_test("get_axes_info")
usethis::use_test("get_aspect_ratio")
usethis::use_test("get_plot_complexity")
usethis::use_test("auto_save_plot")
usethis::use_test("get_plot_info")
# test
devtools::test()

# install the package
devtools::install()


p1 <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, disp)) +
    ggplot2::geom_point() +
    ggplot2::facet_wrap(~`cyl`) +
    labs(title = "plot 1", subtitle = "subtitle 1")
p2 <- ggplot2::ggplot(mtcars, ggplot2::aes(hp, wt)) +
    ggplot2::geom_point() +
    ggplot2::facet_wrap(~`gear`) +
    labs(title = "plot 2", subtitle = "subtitle 2")
p3 <- ggplot2::ggplot(mtcars, ggplot2::aes(drat, qsec)) +
    ggplot2::geom_point() +
    ggplot2::facet_wrap(~`carb`) +
    labs(title = "plot 2", subtitle = "subtitle 2")
plot_lst <- list(p1, p2, p3)

# Call the function with a temporary file path
temp_file <- "example_images/test_withauto.png"
auto_save_plot(plot_lst, temp_file, verbose = TRUE)

ggsave(plot = p1 + p2 + p3, filename = file.path("example_images/test-no_auto.png"))
