test_that("auto_save_plot saves a plot to a file", {
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

  p3 <- ggplot2::ggplot(mtcars, ggplot2::aes(factor(cyl), qsec, fill = factor(cyl))) +
    ggplot2::geom_boxplot() +
    ggplot2::labs(
      title = "plot 3",
      subtitle = "subtitle 3",
      caption = "caption" # add a caption
    ) +
    ggpubr::stat_compare_means(
      label.x.npc = "middle",
      ggplot2::aes(label = ggplot2::after_stat(p.signif)),
      method = "t.test", ref.group = "4",
      comparisons = list(c("4", "6"), c("4", "8"), c("6", "8")),
      label.y = c(23, 22, 21)
    )
  plot_lst <- list(p1, p2, p3)

  # Call the function with a temporary file path
  temp_file <- tempfile(fileext = ".pdf")
  temp_dir <- "test"
  auto_save_plot(
    plot_lst = plot_lst,
    filename = file.path(temp_dir, temp_file),
    ncol = 1,
    verbose = TRUE
  )

  # Check that the file was created
  expect_true(file.exists(file.path(temp_dir, temp_file)))

  # Clean up the temporary file
  unlink(temp_dir, recursive = TRUE, force = TRUE)
})
