# Visual Acuity project

Files related to the visual acuity database/meta-analysis project carried out by Rick Gilmore's lab group.

The goal of the project is to aggregate data about performance on the Teller Visual Acuity card measure in order to summarize what is known about the development of grating visual acuity in human infants and children.

## Contents

- `src/`: Source code for the protocol and analysis.
- `docs/`: Root directory for the rendered website for the project. Once there are materials to render, the site will be found at <https://gilmore-lab.github.io/visual-acuity/>.
- `R/`: Code used for site-wide purposes. 

## Rendering the site

- Clone the repo.
- Install `renv` via `install.packages('renv')`.
- Install dependencies via `renv::restore()`.
- From a terminal, execute `quarto render src`.
- View the rendered site in your browser by opening `docs/index.html`.