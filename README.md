This repository contains code to build cosponsorship networks from bills passed in the [lower/national chamber](http://www.parlament.ch/) of the Swiss Parliament.

- [interactive demo](http://f.briatte.org/parlviz/swparl)
- [static plots](http://f.briatte.org/parlviz/swparl/plots.html)
- [more countries](https://github.com/briatte/parlnet)

# HOWTO

Replicate by running `make.r` in R.

The `data.r` script downloads information on bills and sponsors, using information from the website of the Swiss parliament and from its [open data portal](http://ws.parlament.ch/). All sponsor photos should download fine.

The `build.r` script then assembles the edge lists and plots the networks, with the help of a few routines coded into `functions.r`. Adjust the parameters in `make.r` to skip the plots or to change the node placement algorithm.

# DATA

## Bills

- `chamber` -- chamber of introduction (1: National or 2: States)
- `legislature` -- legislature
- `id` -- unique identifier
- `date` -- date of introduction (yyyy-mm-dd)
- `title` -- short title
- `sponsors` -- semicolon-separated URLs of single first author
- `n_au` -- total number of sponsors (first author + cosponsors)

## Sponsors

- `legislature` -- legislature (imputed from date of entry)
- `id` -- unique identifier (points to profile URL)
- `chamber` -- chamber (1: National or 2: States)
- `name` -- full name
- `sex` -- gender
- `born` -- year of birth
- `party` -- political party
- `constituency` -- constituency
- `nyears` -- time in office since legislature 44, in years

__Note:__ the code uses French party abbreviations and English party names. Three regional party branches are grouped with larger formations: the single sponsor for _Alternative de Gauche_ in Geneva is grouped with the _Parti Suisse du Travail_, the Greens from Bern (_Grünes Bündnis_) and Zoug (_Alternative Canton de Zoug_) are grouped with the Swiss Federation of Green Parties, and the branches of the Christian Social Party in Obwalden and Wallis are grouped with their main party.
