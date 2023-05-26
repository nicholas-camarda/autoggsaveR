test_that("auto_save_plot saves a plot to a file", {
  # Create a list of plots with facets
  p1 <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, disp)) +
    ggplot2::geom_point() +
    ggplot2::facet_wrap(~`cyl`)
  p2 <- ggplot2::ggplot(mtcars, ggplot2::aes(hp, wt)) +
    ggplot2::geom_point() +
    ggplot2::facet_wrap(~`cyl`)
  plot_lst <- list(p1, p2)

  # Call the function with a temporary file path
  temp_file <- tempfile(fileext = ".png")
  temp_dir <- "test"
  auto_save_plot(plot_lst, temp_dir, temp_file, verbose = FALSE)

  # Check that the file was created
  expect_true(file.exists(file.path(temp_dir, temp_file)))

  # Clean up the temporary file
  unlink(temp_dir, recursive = TRUE, force = TRUE)
})
