# party colors

colors = c(
  "AL/LG" = "#B2182B",           # Alternative Left, dark red (not used) -- dark red
  "PDA/PST" = "#FB8072",         # Communist, dark red, n = 1, red (not used) -- light red
  "GPS/PES/GB" = "#4DAF4A",      # leftwing Greens, green -- green
  "SPS/PSS" = "#E41A1C",         # social-democrats, red -- red
  "GLP/PVL" = "#B3DE69",         # centrist Greens, light green -- light green
  "LDU" = "#444444",             # Ring of Independents (Migros), dissolved to red-green -- dark grey
  "CVP/PDC/PPD" = "#FDB462",     # centre-right Christian-Democrats, light brown -- light orange
  "EVP/PEV" = "#FFFFB3",         # centrist Christian-Democrats, light yellow -- light yellow
  "CSP/PCS" = "#01665E",         # centre-left Christians, teal -- teal
  "LPS/PLS-FDP/PLR" = "#377EB8", # centre-right (LPS/PLS joined FDP/PLR), blue -- blue
  "SVP/UDC" = "#01665E",         # rightwing, green -- dark green
  "BDP/PBD" = "#FFFF33",         # centre-right, yellow -- yellow
  "SLB/MSL" = "#FF7F00",         # conservative, orange (not used) -- orange
  "FPS/PSL" = "#A65628",         # rightwing, brown -- brown
  "EDU/UDF" = "#C51B7D",         # Christian right, magenta (not used) -- magenta
  "LEGA" = "#80B1D3",            # Ticino League, regionalist, light blue -- light blue
  "MCR/MCG" = "#984EA3",         # Mouvement Citoyens Romand, rightwing regionalist, yellow -- purple
  "IND" = "#AAAAAA"              # unaffiliated (many, plus minor/not used parties) -- light grey
)

# ParlGov Left/Right scores

scores = c(
  "AL/LG" = Inf, # missing, not used
  "PDA/PST" = 0.5, # not used
  "GPS/PES/GB" = 1.7,
  "SPS/PSS" = 1.8,
  "GLP/PVL" = 2.6,
  "LDU" = 3.3,
  "CVP/PDC/PPD" = 4.7,
  "EVP/PEV" = 4.9,
  "CSP/PCS" = 6.2,
  "LPS/PLS-FDP/PLR" = 6.8,
  "SVP/UDC" = 7.4,
  "BDP/PBD" = 7.4,
  "SLB/MSL" = Inf, # missing, not used
  "FPS/PSL" = 8.1,
  "EDU/UDF" = 8.7, # not used
  "LEGA" = 8.7,
  "MCR/MCG" = Inf, # missing
  "IND" = Inf
)

stopifnot(names(colors) == names(scores))
order = names(colors)[ order(scores) ]
