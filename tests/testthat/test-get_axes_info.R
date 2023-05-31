test_that("get_axes_info works", {
  p1 <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, disp)) +
    ggplot2::geom_point() +
    ggplot2::facet_wrap(~`cyl`) +
    ggplot2::labs(title = "plot 1", subtitle = "subtitle 1")
  p2 <- ggplot2::ggplot(mtcars, ggplot2::aes(hp, wt)) +
    ggplot2::geom_point() +
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

  axes_info <- get_axes_info(plot_lst)
  expect_equal(axes_info$num_x_items, c(32, 32, 32))
  expect_equal(axes_info$num_y_items, c(32, 32, 32))
})
