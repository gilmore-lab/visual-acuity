# R/functions.R.

#------------------------------------------------------------------------------
render_all <- function() {
  rmarkdown::render("irb/README.Rmd")
  bookdown::render_book('src')
}

#------------------------------------------------------------------------------
# Renders anew all reports and pages and opens root HTML site
render_view <- function(open_rpt = TRUE, rpt_url = "src/index.html") {
  render_all()
  if (open_rpt)
    browseURL(rpt_url)
}