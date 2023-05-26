test_that("get_plot_info returns correct number of plots, layers, and facets", {
  # Create a list of plots
  p1 <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, disp)) +
    ggplot2::geom_point()
  p2 <- ggplot2::ggplot(mtcars, ggplot2::aes(hp, wt)) +
    ggplot2::geom_point()
  plot_lst <- list(p1, p2)

  # Call the function
  result <- get_plot_info(plot_lst, verbose = FALSE)

  # Check that the result is as expected
  expect_equal(result$num_plots, 2)
  expect_equal(result$num_layers, 2)
  expect_equal(result$num_facets, 0)

  # Create a list of plots with facets
  p1 <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, disp)) +
    ggplot2::geom_point() +
    ggplot2::facet_wrap(~`cyl`)
  p2 <- ggplot2::ggplot(mtcars, ggplot2::aes(hp, wt)) +
    ggplot2::geom_point() +
    ggplot2::facet_wrap(~`cyl`)
  plot_lst <- list(p1, p2)

  # Call the function
  result <- get_plot_info(plot_lst, verbose = FALSE)

  # Check that the result is as expected
  expect_equal(result$num_plots, 2)
  expect_equal(result$num_layers, 2)
  expect_equal(result$num_facets, 6)
})
