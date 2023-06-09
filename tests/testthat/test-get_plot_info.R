test_that("get_plot_info works", {
  # Create a list of plots with facets
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

  p3 <- ggplot2::ggplot(mtcars, ggplot2::aes(drat, qsec, color = cyl)) +
    ggplot2::geom_point() +
    ggplot2::facet_wrap(~`carb`) +
    ggplot2::labs(
      title = "plot 3",
      subtitle = "subtitle 3",
      caption = "caption" # add a caption
    )
  plot_lst <- list(p1, p2, p3)

  plot_info <- get_plot_info(plot_lst, verbose = TRUE)
  expect_equal(plot_info$num_plots, 3)
  expect_equal(plot_info$num_layers, c(1, 2, 1))
  expect_equal(plot_info$num_facets, c(3, 3, 6))
  expect_equal(plot_info$num_text, c(4, 4, 5))
})
