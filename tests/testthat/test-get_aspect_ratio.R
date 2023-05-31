test_that("get_aspect_ratio works works", {
  p1 <- ggplot2::ggplot(mtcars, ggplot2::aes(mpg, disp)) +
    ggplot2::geom_point() +
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
  axes_info <- get_axes_info(plot_lst)
  adjusted_aspect_ratio <- get_aspect_ratio(plot_lst, plot_info, axes_info)
  # this works...
  expect_equal(adjusted_aspect_ratio, c(1.31607401, 1.31607401, 1.56508458))
})
