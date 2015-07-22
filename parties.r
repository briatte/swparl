# party groups

groups = c(
  "PDT" = "Party of Labour",
  "FRAP" = "Frauen Macht Politik!", # single member, 1999 and 2003, now in PSS
  "PES" = "Green Party",
  "PSS" = "Socialist Party",
  "PVL" = "Green Liberal Party",
  "ADI" = "Alliance of Independents", # Migros, dissolved to red-green
  "PDC" = "Christian Democratic People's Party",
  "PEV" = "Evangelical People's Party",
  "PCS" = "Christian Social Party",
  "PLR" = "Free Democratic Party",
  "PLS" = "Liberal Party",
  "UDC" = "Swiss People's Party",
  "PBD" = "Conservative Democratic Party",
  "FPS" = "Freedom Party", # now in FDP-The Liberals
  "UDF" = "Federal Democratic Union",
  "LEGA" = "Ticino League",
  "DS"  = "Swiss Democrats",
  "MCR" = "Geneva Citizens Movement",
  "IND" = "independent"
)

# party colors

colors = c(
  "PDT" = "#B2182B",      # dark red
  "FRAP" = "#F781BF",     # pink
  "PES" = "#4DAF4A",      # green
  "PSS" = "#E41A1C",      # red
  "PVL" = "#B3DE69",      # light green
  "ADI" = "#444444",      # dark grey
  "PDC" = "#FDB462",      # light brown -- light orange
  "PEV" = "#FFFFB3",      # light yellow
  "PCS" = "#01665E",      # teal
  "PLR" = "#377EB8",      # blue
  "PLS" = "#053061",      # dark blue
  "UDC" = "#00441B",      # green -- very dark green
  "PBD" = "#FFFF33",      # yellow
  "FPS" = "#A65628",      # brown
  "UDF" = "#C51B7D",      # magenta
  "LEGA" = "#80B1D3",     # light blue
  "DS"  = "#000000",      # black
  "MCR" = "#FF7F00",      # yellow/red -- orange
  "IND" = "#AAAAAA"       # light grey
)

# ParlGov Left/Right scores

scores = c(
  "PDT" = 0.5,
  "FRAP" = 1.3,
  "PES" = 1.7,
  "PSS" = 1.8,
  "PVL" = 2.6,
  "ADI" = 3.3,
  "PDC" = 4.7,
  "PEV" = 4.9,
  "PCS" = 6.2,
  "PLR" = 6.3,
  "PLS" = 7.3,
  "UDC" = 7.4,
  "PBD" = 7.4,
  "FPS" = 8.1,
  "UDF" = 8.7,
  "LEGA" = 8.7,
  "DS" = 9.4,
  "MCR" = Inf, # missing
  "IND" = Inf
)

stopifnot(names(colors) == names(scores))
order = names(colors)[ order(scores) ]
