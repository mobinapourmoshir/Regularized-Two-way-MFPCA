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
  size: "'36x24' or '48x36''",

  // The poster's title.
  title: "Paper Title",

  // A string of author names.
  authors: "Author Names (separated by commas)",

  // Department name.
  departments: "Department Name",

  // University logo.
  univ_logo: "Logo Path",

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
  // Tested on 36in x 24in, 48in x 36in, and 36in x 48in posters.
  // For 2-column posters, you may need to tweak these values.
  // See ./examples/example_2_column_18_24.typ for an example.

  // Any keywords or index terms that you want to highlight at the beginning.
  keywords: (),

  // Number of columns in the poster.
  num_columns: "3",

  // University logo's scale (in %).
  univ_logo_scale: "100",

  // University logo's column size (in in).
  univ_logo_column_size: "0",

  // Title and authors' column size (in in).
  title_column_size: "20",

  // Poster title's font size (in pt).
  title_font_size: "38",

  // Authors' font size (in pt).
  authors_font_size: "25",

  // Footer's URL and email font size (in pt).
  footer_url_font_size: "20",

  // Footer's text font size (in pt).
  footer_text_font_size: "20",

  // The poster's content.
  body
) = {
  // Set the body font.
  set text(font: "STIX Two Text", size: 19pt)
  let sizes = size.split("x")
  let width = int(sizes.at(0)) * 1in
  let height = int(sizes.at(1)) * 1in
  univ_logo_scale = int(univ_logo_scale) * 1%
  title_font_size = int(title_font_size) * 1pt
  authors_font_size = int(authors_font_size) * 1pt
  num_columns = int(num_columns)
  univ_logo_column_size = int(univ_logo_column_size) * 1in
  title_column_size = int(title_column_size) * 1in
  footer_url_font_size = int(footer_url_font_size) * 1pt
  footer_text_font_size = int(footer_text_font_size) * 1pt

  // Configure the page.
  // This poster defaults to 36in x 24in.
  set page(
    width: width,
    height: height,
    margin:
      (top: 1in, left: 2in, right: 2in, bottom: 2in),
    footer: [
      #set align(center)
      #set text(32pt)
      #block(
        fill: rgb("#d3d3d3"),
        width: 100%,
        inset: 20pt,
        radius: 10pt,
        [
          #text(font: "Courier", size: footer_url_font_size, footer_url)
          #h(1fr)
          #text(size: footer_text_font_size, smallcaps(footer_text))
          #h(1fr)
          #text(font: "Courier", size: footer_url_font_size, footer_email_ids)
        ]
      )
    ]
  )

  // Configure equation numbering and spacing.
  set math.equation(numbering: "(1)")
  show math.equation: set block(spacing: 0.65em)

  // Configure lists.
  set enum(indent: 10pt, body-indent: 9pt)
  set list(indent: 10pt, body-indent: 9pt)

  // Configure headings.
  set heading(numbering: "I.A.1.")
  show heading: it => locate(loc => {
    // Find out the final number of the heading counter.
    let levels = counter(heading).at(loc)
    let deepest = if levels != () {
      levels.last()
    } else {
      1
    }

    set text(24pt, weight: 400)
    if it.level == 1 [
      // First-level headings are centered smallcaps.
      #set align(center)
      #set text({ 32pt })
      #show: smallcaps
      #v(50pt, weak: true)
      #if it.numbering != none {
        numbering("I.", deepest)
        h(7pt, weak: true)
      }
      #it.body
      #v(35.75pt, weak: true)
      #line(length: 100%)
    ] else if it.level == 2 [
      // Second-level headings are run-ins.
      #set text(style: "italic")
      #v(32pt, weak: true)
      #if it.numbering != none {
        numbering("i.", deepest)
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
  align(center,
    grid(
  rows: 2,
  columns: (univ_logo_column_size, title_column_size),
  column-gutter: -30pt,
  row-gutter: 20pt,

  // University logo (scaled explicitly)
  place(dx: -4.5in, dy: -0.5in, image(univ_logo, width: 3.7in)),

  // Title and author info (multi-line)
  block(
    text(title_font_size, title + "\n\n") +
    text(authors_font_size, emph(authors) + "\n") +
    text(authors_font_size, "Marquette University\n") +
    text(authors_font_size, "Department of Mathematical and Statistical Sciences")
  )
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
// If you are creating or packaging a custom typst template you will likely
// want to replace this file and 'typst-template.typ' entirely. You can find
// documentation on creating typst templates here and some examples here:
//   - https://typst.app/docs/tutorial/making-a-template/
//   - https://github.com/typst/templates

#show: doc => poster(
   title: [Functional Autoencoders with Temporal Latent Dynamics for Forecasting], 
  // TODO: use Quarto's normalized metadata.
   authors: [Mobina Pourmoshir, Dr.~Mehdi Maadooliat], 
   departments: [Department of Mathematical and Statistical Sciences], 
   size: "36x24", 

  // Institution logo.
   univ_logo: "./images/MU.jpg", 

  // Footer text.
  // For instance, Name of Conference, Date, Location.
  // or Course Name, Date, Instructor.
   footer_text: [Marquette University], 

  // Any URL, like a link to the conference website.
   footer_url: [https:\/\/github.com/mobinapourmoshir/ReMPCA], 

  // Emails of the authors.
   footer_email_ids: [mobina.pourmoshir\@marquette.edu], 

  // Color of the footer.
   footer_color: "ebcfb2", 

  // DEFAULTS
  // ========
  // For 3-column posters, these are generally good defaults.
  // Tested on 36in x 24in, 48in x 36in, and 36in x 48in posters.
  // For 2-column posters, you may need to tweak these values.
  // See ./examples/example_2_column_18_24.typ for an example.

  // Any keywords or index terms that you want to highlight at the beginning.
  

  // Number of columns in the poster.
  

  // University logo's scale (in %).
  

  // University logo's column size (in in).
  

  // Title and authors' column size (in in).
  

  // Poster title's font size (in pt).
  

  // Authors' font size (in pt).
  

  // Footer's URL and email font size (in pt).
  

  // Footer's text font size (in pt).
  

  doc,
)

= Background
<background>
- Functional data arise in many applications such as fertility rates, biomedical signals, and environmental measurements.

- Classical approaches such as Functional Principal Component Analysis (FPCA) provide linear dimension reduction.

- However, FPCA:

  - cannot capture nonlinear structure \
  - struggles with phase variation and deformation

- #strong[Goal:] \
  Develop a framework that:

  - learns #strong[nonlinear representations]
  - preserves #strong[smoothness]
  - supports #strong[accurate forecasting]

#horizontalrule

= Methodology: Functional Autoencoder (FAE)
<methodology-functional-autoencoder-fae>
We propose a #strong[two-stage framework] combining representation learning and time-series modeling.

== Step 1: Representation Learning
<step-1-representation-learning>
Let \
\[ {x}\_t = (X\_t(s\_1), , X\_t(s\_J))^ \]

- Encoder: \[ {h}#emph[t = E];({x}\_t) \]

- Decoder (basis expansion): \[ #emph[t(s) = ];{m=1}^M \_{tm} \_m(s) \]

- Reconstruction: \[ \_t = {}{C}{h}\_t \]

#horizontalrule

== Penalized Objective
<penalized-objective>
\[ = \_{t=1}^T |{x}\_t - \_t|^2 + ( \_t(s) )^2 ds \]

- Ensures:
  - smoothness \
  - noise reduction \
  - stable representations

#horizontalrule

== Step 2: Latent Temporal Modeling
<step-2-latent-temporal-modeling>
Latent series: \[ {{h}#emph[t}];{t=1}^T \]

Modeled via VAR: \[ {h}#emph[t = ];{i=1}^p A\_i {h}\_{t-i} + \_t \]

Forecast: \[ #emph[{T+1}, , ];{T+L} \]

#horizontalrule

== Step 3: Decode Forecasts
<step-3-decode-forecasts>
\[ #emph[{T+}(s) = D];(\_{T+}) \]

#horizontalrule

= Proposed Framework (FAE-New)
<proposed-framework-fae-new>
#align(center,
  image("images/FAE-New.pdf", width: 10in)
)
= Algorithm
<algorithm>
#block(
  inset: 10pt,
  stroke: 1pt,
  radius: 5pt,
)[
  *Functional Autoencoders with Temporal Latent Dynamics*

  1. *Input:* Functional data $\{X_t(\cdot)\}_{t=1}^T$

  2. *Train Autoencoder*
     - Encode: ${h}_t = E_\theta({x}_t)$  
     - Decode: $\widehat{{x}}_t = D_\theta({h}_t)$  
     - Minimize penalized reconstruction loss  

  3. *Latent Modeling*
     - Fit VAR model on $\{{h}_t\}$  

  4. *Forecast*
     - Compute $\widehat{{h}}_{T+1}, \dots, \widehat{{h}}_{T+L}$  

  5. *Decode Forecasts*
     - $\widehat{X}_{T+\ell}(s) = D_\theta(\widehat{{h}}_{T+\ell})$
]
= Simulation Study
<simulation-study>
#block(
  inset: 8pt,
  radius: 5pt,
)[
  *Comparison Setup*

  • FPCA + VAR (linear baseline)  
  • FAE + VAR (proposed)

  *Scenarios*

  • Linear setting → both methods perform similarly  
  • Nonlinear setting → includes warping, deformation, nonlinear dynamics  

  *Key Finding*

  • FAE captures nonlinear structure  
  • FPCA struggles with phase variation
]
= Real Data Application
<real-data-application>
== USA Fertility Data
<usa-fertility-data>
\`\`\`{=typst} id="img\_fertility" \#align(center, image("images/usafertility.pdf", width: 8in) ) \#block( inset: 8pt, radius: 5pt, )\[ #emph[Dataset Description]

• Age-specific fertility rates in the United States

• Time span: 1933–2023

• Each year is represented as a smooth curve over age

• Data exhibit strong temporal dependence and smooth structure

• Suitable for functional time series modeling \]

````
### Forecasting Setup





```{=typst}
#block(
  inset: 8pt,
  radius: 5pt,
)[
  *Training Period*  
  • 1933–2018  

  *Testing Period*  
  • 2019–2023  

  *Forecasting Pipelines*

  • FPCA → VAR → Reconstruction  

  • FAE → VAR → Decode (proposed)

  *Goal*

  • Compare linear vs nonlinear representations  
  • Evaluate multi-step forecasting accuracy
]
````

=== Forecasting Results
<forecasting-results>
#align(center,
  [
    FPCA+VAR: relRMSE = 0.195 \\
    FAE+VAR: relRMSE = 0.076
  ]
)
#align(center,
  image("images/fertility_forecasts.pdf", width: 10in)
)
#block(
  inset: 8pt,
  radius: 5pt,
)[
  *Key Observations*

  • FAE significantly reduces forecasting error  

  • Better captures peak fertility age  

  • Preserves full curve shape  

  • Tracks temporal evolution more accurately than FPCA  

  • Demonstrates advantage of nonlinear latent representation
]
= Conclusion
<conclusion>
#block(
  inset: 8pt,
  radius: 5pt,
)[
  • FAE provides nonlinear functional representations  

  • Significantly improves forecasting accuracy  

  • Combines:
    - Functional Data Analysis  
    - Deep Learning  
    - Time-Series Modeling  

  • Applicable to:
    - Biomedical data  
    - Environmental data  
    - Demographic studies  
]
= Reference
<reference>
#set text(size: 9pt)



