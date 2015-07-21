This repository contains code to build cosponsorship networks from bills passed in the [lower/national chamber](http://www.parlament.ch/) of the Swiss Parliament.

- [interactive demo](http://f.briatte.org/parlviz/swparl)
- [static plots](http://f.briatte.org/parlviz/swparl/plots.html)
- [more countries](https://github.com/briatte/parlnet)

# HOWTO

Replicate by running `make.r` in R.

The `data.r` script downloads information on bills and sponsors. See also the [open data portal](http://ws.parlament.ch/) of the Swiss parliament, although its API does not allow querying for sponsor information.

The `build.r` script then assembles the edge lists and plots the networks, with the help of a few routines coded into `functions.r`. Adjust the parameters in `make.r` to skip the plots or to change the node placement algorithm.

# DATA

## Bills

- `url` -- full bill URL
- `file` -- bill filename
- `summary` -- short description
- `description` -- longer description
- `answer` -- whether the executive has replied to the bill
- `status` -- current status of the bill
- `title` -- short title
- `subtitle` -- subtitle
- `date` -- date of introduction (yyyy-mm-dd)
- `council` -- chamber of introduction (National or States)
- `outcome` -- outcome of the bill
- `commissions` -- commission the bill was assigned to
- `authors` -- semicolon-separated URLs of single first author
- `cosponsors` -- semicolon-separated URLs of cosponsors
- `keywords` -- keywords (several hundreds, in German)
- `n_au` -- number of first authors
- `n_co` -- number of cosponsors
- `n_a` -- total number of sponsors
- `legislature` -- legislature, imputed from `date`

## Sponsors

- `url` -- profile URL
- `name` -- sponsor name
- `born` -- year of birth
- `groupname` -- parliamentary group
- `partyname` -- political party
- `constituency` -- constituency
- `mandate` -- mandate years, as date ranges
- `photo` -- photo URL, shorted to filename
