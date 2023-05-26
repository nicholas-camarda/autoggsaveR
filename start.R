library(usethis)
library(devtools)

usethis::use_r("autoggsaveR_functions")

usethis::use_package("ggplot2")
usethis::use_package("patchwork")
usethis::use_package("tidyr")
usethis::use_package("GetoptLong")
usethis::use_package("magrittr")

# add import statements as needed

usethis::use_mit_license("Nicholas Camarda")

usethis::use_git_remote("origin", url = NULL, overwrite = TRUE)

devtools::check()
# fix any errors

devtools::build()

# add tests
usethis::use_test("get_plot_info")
usethis::use_test("get_num_plot_items")
usethis::use_test("auto_save_plot")

# test
devtools::test()

# install the package
devtools::install()
