# capturing some manual tests re: detecting missing user email or name
# https://github.com/jixing475/acwri/pull/1721

dat <- gert::git_config_global()
if ("user.name" %in% dat$name) {
  old_name <- dat$value[dat$name == "user.name"]
  acwri::use_git_config(user.name = NULL)
  withr::defer(acwri::use_git_config(user.name = old_name))
}
if ("user.email" %in% dat$name) {
  old_email <- dat$value[dat$name == "user.email"]
  acwri::use_git_config(user.email = NULL)
  withr::defer(acwri::use_git_config(user.email = old_email))
}
acwri::git_sitrep(scope = "user")
acwri::git_sitrep(scope = "project")
acwri::git_sitrep()
withr::deferred_run()

dat <- gert::git_config_global()
if ("user.name" %in% dat$name) {
  old_name <- dat[dat$name == "user.name", ]$value
  acwri::use_git_config(user.name = NULL)
  withr::defer(acwri::use_git_config(user.name = old_name))
}
acwri::git_sitrep(scope = "user")
acwri::git_sitrep(scope = "project")
acwri::git_sitrep()
withr::deferred_run()

dat <- gert::git_config_global()
if ("user.email" %in% dat$name) {
  old_email <- dat[dat$name == "user.email", ]$value
  acwri::use_git_config(user.email = NULL)
  withr::defer(acwri::use_git_config(user.email = old_email))
}
acwri::git_sitrep(scope = "user")
acwri::git_sitrep(scope = "project")
acwri::git_sitrep()
withr::deferred_run()
