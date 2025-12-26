test_that("basic legacy UI actions behave as expected", {
  # suppress test silencing
  withr::local_options(list(acwri.quiet = FALSE))

  expect_snapshot({
    ui_line("line")
    ui_todo("to do")
    ui_done("done")
    ui_oops("oops")
    ui_info("info")
    ui_code_block(c("x <- 1", "y <- 2"))
    ui_warn("a warning")
  })
})

test_that("legacy UI actions respect acwri.quiet = TRUE", {
  withr::local_options(list(acwri.quiet = TRUE))

  expect_no_message({
    ui_line("line")
    ui_todo("to do")
    ui_done("done")
    ui_oops("oops")
    ui_info("info")
    ui_code_block(c("x <- 1", "y <- 2"))
  })
})

test_that("ui_stop() works", {
  expect_acwri_error(ui_stop("an error"), "an error")
})

test_that("ui_silence() suppresses output", {
  # suppress test silencing
  withr::local_options(list(acwri.quiet = FALSE))

  expect_output(ui_silence(ui_line()), NA)
})
