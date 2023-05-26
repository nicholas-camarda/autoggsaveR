test_that("get_num_plot_items returns correct number of x and y items", {
  # Create a ggplot object
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, disp)) +
    ggplot2::geom_point()

  # Call the function
  result <- get_num_plot_items(p)

  # Check that the result is as expected
  expect_equal(result$num_x_items, length(unique(mtcars$mpg)))
  expect_equal(result$num_y_items, length(unique(mtcars$disp)))
})
