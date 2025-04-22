// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: white, width: 100%, inset: 8pt, body))
      }
    )
}


#let poster(
  // The poster's size.
  size: "'36x24' or '48x36' or '72x30'",

  // The poster's title.
  title: "Paper Title",

  // A string of author names.
  authors: "Author Names (separated by commas)",

  // Department name.
  departments: "Department Name",

  // University logo.
  univ_logo: "Logo Path",
  
  // University image.
  univ_image: "./include/img/unwatermarked-mt-nittany.jpg",

  // Footer text.
  // For instance, Name of Conference, Date, Location.
  // or Course Name, Date, Instructor.
  footer_text: "Footer Text",

  // Any URL, like a link to the conference website.
  footer_url: "Footer URL",

  // Email IDs of the authors.
  footer_email_ids: "Email IDs (separated by commas)",

  // Color of the footer.
  footer_color: "Hex Color Code",

  // DEFAULTS
  // ========
  // For 3-column posters, these are generally good defaults.
  // Tested on 36in x 24in, 48in x 36in, 72in x 30in, and 36in x 48in posters.
  // For 2-column posters, you may need to tweak these values.
  // See ./examples/example_2_column_18_24.typ for an example.

  // Any keywords or index terms that you want to highlight at the beginning.
  keywords: (),

  // Number of columns in the poster.
  num_columns: "3",

  // University logo's scale (in %).
  univ_logo_scale: "30",
  
  // University image's scale (in %).
  univ_image_scale: "100",

  // University logo's column size (in in).
  univ_logo_column_size: "8",

  // Title and authors' column size (in in).
  title_column_size: "50",
  
  // University image's column size (in in).
  univ_image_column_size: "8",

  // Poster title's font size (in pt).
  title_font_size: "48",

  // Authors' font size (in pt).
  authors_font_size: "36",

  // Footer's URL and email font size (in pt).
  footer_url_font_size: "36",

  // Footer's text font size (in pt).
  footer_text_font_size: "36",

  // The poster's content.
  body
) = {
  // Set the body font. Use a Google Font you like. Set size. Here we used Open Sans.
  set text(font: "Open Sans", size: 32pt) // Can change to 12pt for small size
  let sizes = size.split("x")
  let width = int(sizes.at(0)) * 1in
  let height = int(sizes.at(1)) * 1in
  univ_logo_scale = int(univ_logo_scale) * 1%
  univ_image_scale = int(univ_image_scale) * 1%
  title_font_size = int(title_font_size) * 1pt
  authors_font_size = int(authors_font_size) * 1pt
  num_columns = int(num_columns)
  univ_logo_column_size = int(univ_logo_column_size) * 1in
  univ_image_column_size = int(univ_image_column_size) * 1in
  title_column_size = int(title_column_size) * 1in
  footer_url_font_size = int(footer_url_font_size) * 1pt
  footer_text_font_size = int(footer_text_font_size) * 1pt

  // Configure the page.
  // This poster is based on a default of 36in x 24in
  // below are commands from raw typst
  // lots of options to configure the page can be
  // found at https://typst.app/docs 
  
  set page(
    width: width,
    height: height,
    margin: 
      (top: 1in, left: 1in, right: 1in, bottom: 1in),
    footer: [
      #set align(center)
      #set text(32pt) // altered for 72 x 30
      #block(
        fill: rgb(footer_color),
        width: 100%,
        inset: 20pt,
        radius: 10pt,
    // note fonts modifiable in the footer
        [
          #text(size: footer_text_font_size, smallcaps(footer_text)) 
          #h(1fr) 
          #text(font: "Open Sans", size: footer_url_font_size, footer_url) 
          #h(1fr) 
          #text(font: "Open Sans", size:  footer_url_font_size, footer_email_ids)
        ]
      )
    ]
  )

  // Configure equation numbering and spacing.
  set math.equation(numbering: "(1)")
  show math.equation: set block(spacing: 0.65em)

  // Configure lists.
  // modify indents as desired
  set enum(indent: 30pt, body-indent: 9pt) 
  set list(indent: 30pt, body-indent: 9pt)

  // Configure headings.
  // modify numbering as desired, if any
  set heading(numbering: "I.A.1.")
  show heading: it => locate(loc => {
    // Find out the final number of the heading counter.
    let levels = counter(heading).at(loc)
    let deepest = if levels != () {
      levels.last()
    } else {
      1
    }

    set text(40pt, weight: 700)
    if it.level == 1 [
      // First-level headings are left-aligned numbered but not in (smallcaps) - perhaps this font does not do smallcaps.
      #set align(left)
      #set text({ 44pt })
      #show: smallcaps
      #v(50pt, weak: true)
      #if it.numbering != none {
        numbering("1.", deepest)
        h(7pt, weak: true)
      }
      #it.body
      #v(35.75pt, weak: true)
      #line(length: 100%)
    ] else if it.level == 2 [
      // Second-level headings are run-ins.
      // italic, 32 pt, numbered w/letters
      #set text(style: "italic", weight: 600)
      #v(32pt, weak: true)
      #if it.numbering != none {
        // removed numbering from subheadings
        h(7pt, weak: true)
      }
      #it.body
      #v(10pt, weak: true)
    ] else [
      // Third level headings are run-ins too, but different.
      #if it.level == 3 {
        numbering("1)", deepest)
        [ ]
      }
      _#(it.body):_
    ]
  })

  // Arranging the logo, title, authors, and department in the header.
  // Could add a 3rd column for Michigan image of hospital or campus
  // extra line break "\n" added to authors to separate from title
  // emph() causes italics
  //inset pads around the text, radius rounds the corners
 align(center,
    grid(
      rows: 2,
      columns: (univ_logo_column_size, title_column_size, univ_image_column_size),
      column-gutter: 5pt,
      row-gutter: 5pt,
      image(univ_logo, width: univ_logo_scale),
      box(stroke: rgb("#a4c5e6") + 10pt, 
          fill: rgb("#1c437c"),
            text(title_font_size, title + "\n", 
            fill: rgb("#ffffff")) + 
            text(authors_font_size, emph("\n" + authors) + 
            "\n" + departments, fill: rgb("#ffffff")), 
          radius: 15pt, inset: 30pt),
      image(univ_image, width: univ_image_scale)
    )
  )

  // Start three column mode and configure paragraph properties.
  show: columns.with(num_columns, gutter: 64pt)
  set par(justify: true, first-line-indent: 0em)
  show par: set block(spacing: 0.65em)

  // Display the keywords.
  if keywords != () [
      #set text(24pt, weight: 400)
      #show "Keywords": smallcaps
      *Keywords* --- #keywords.join(", ")
  ]

  // Display the poster's contents.
  body
}

// Typst custom formats typically consist of a 'typst-template.typ' (which is
// the source code for a typst template) and a 'typst-show.typ' which calls the
// template's function (forwarding Pandoc metadata values as required)
//
// This is an example 'typst-show.typ' file (based on the default template  
// that ships with Quarto). It calls the typst function named 'article' which 
// is defined in the 'typst-template.typ' file. 
//
// This file calls the 'poster' function defined in the 'typst-template.typ' file to render your poster to PDF when you press the Render button.
// Make any edits to the template in the typst-template.typ file
//
// If you are creating or packaging a custom typst template you will likely
// want to replace this file and 'typst-template.typ' entirely. You can find
// documentation on creating typst templates here and some examples here:
//   - https://typst.app/docs/tutorial/making-a-template/
//   - https://github.com/typst/templates

#show: doc => poster(
   title: [Synthesizing evidence about developmental patterns in human visual acuity as measured by Teller Acuity Cards], 
  // TODO: use Quarto's normalized metadata.
   authors: [R.O. Gilmore#super[1];, J. DiFulvio#super[1];, B. Beamer#super[1];, N. Cruz#super[1];], 
   departments: [#super[1];Department of Psychology, The Pennsylvania State University], 
   size: "60x36", 

  // Institution logo.
   univ_logo: "./include/img/penn-state-shield.jpg", 

  // Institution image.
  
  
  // Footer text.
  // For instance, Name of Conference, Date, Location.
  // or Course Name, Date, Instructor.
   footer_text: [Vision Sciences Society 2025], 

  // Any URL, like a link to the conference website.
   footer_url: [Download this poster at: https:\/\/gilmore-lab.github.io], 

  // Emails of the authors.
   footer_email_ids: [rog1\@psu.edu], 

  // Color of the header.
  
  
  // Color of the footer.
   footer_color: "a4c5e6", 

  // DEFAULTS
  // ========
  // For 3-column posters, these are generally good defaults.
  // Tested on 36in x 24in, 48in x 36in, and 36in x 48in posters.
  // Typical medical meeting posters are 60 or 72 in wide x 30 or 36 in tall
  // in the US
  // Or 100 cm wide by 189 cm tall  in Europe.
  // For 2-column posters, you may need to tweak these values.
  // See ./examples/example_2_column_18_24.typ for an example.

  // Any keywords or index terms that you want to highlight at the beginning.
  

  // Number of columns in the poster.
  

  // University logo's scale (in %).
   univ_logo_scale: 75, 

  // University logo's column size (in in).
   univ_logo_column_size: 4, 

  // University image's scale (in %).
   univ_image_scale: 80, 
  
    // University image's column size (in in).
   univ_image_column_size: 6, 
  
  // Title and authors' column size (in in).
   title_column_size: 48, 

  // Poster title's font size (in pt).
   title_font_size: 100, 

  // Authors' font size (in pt).
   authors_font_size: 52, 

  // Footer's URL and email font size (in pt).
  

  // Footer's text font size (in pt).
  

  doc,
)

#block[
#heading(
level: 
1
, 
numbering: 
none
, 
[
Aims
]
)
]
Replication is a cornerstone of scientific rigor and a prerequisite for cumulative science. This project synthesized evidence from published research that employed a widely used measure of grating visual acuity (VA), Teller Acuity Cards (TAC). We sought to capture findings about the development of VA in early childhood into an aggregated dataset and share the dataset openly.

#block[
#heading(
level: 
1
, 
numbering: 
none
, 
[
Methods
]
)
]
+ Paper search
+ Paper filtering, evaluation
+ Data aggregation, cleaning
+ Data visualization

#block[
#heading(
level: 
1
, 
numbering: 
none
, 
[
Results
]
)
]
== Sources Synthesized
<sources-synthesized>
#table(
  columns: (21.62%, 37.84%, 40.54%),
  align: (auto,center,auto,),
  table.header([#strong[Category];], [#emph[n];], [#strong[Comments];],),
  table.hline(),
  [Found in search], [751], [Terms: "teller acuity cards", "visual acuity cards", or "teller cards"],
  [Had PDFs or full text versions], [433], [Continuing to seek additional papers],
  [No PDF/full text available], [318], [],
  [Extractable data], [27], [Includes data summarized by others.],
)
== Typically developing children
<typically-developing-children>
#box(image("vss-2025-submission_files/figure-html.svg"))

= Results: Aypically developing children
<results-aypically-developing-children>
#box(image("vss-2025-poster_files/mediabag/fig-atypical-group-b.png"))

== Individual data: Typically developing children
<individual-data-typically-developing-children>
#box(image("vss-2025-poster_files/mediabag/fig-typical-indiv-by.png"))

= Conclusions
<conclusions>
#block(
fill:luma(210),
inset:25pt,
radius:15pt,
stroke:5pt + blue,
[
- Synthesizing evidence about core facets of human visual development is important and illuminating.

- Idiosyncratic practices for reporting data in published papers makes evidence synthesis challenging.

- Future work will involve contacting individual researchers to seek unpublished or more complete datasets from published work.

- Vision scientists should adopt open data sharing practices more widely.

])

= Data availability
<data-availability>
Data and code used in the preparation of this report are available at: #link("https://gilmore-lab.github.io/visual-acuity");.

#box(image("vss-2025-poster_files/figure-typst/qr-code-site-1.svg"))

= References
<references>




