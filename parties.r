# party groups

groups = c(
  "AL/LG" = "Alternative Left, AL/LG/LS", # not used, recoded as IND
  "PDA/PST" = "Swiss Party of Labour, PdA/PST", # not used, recoded as IND
  "GPS/PES/GB" = "Green Party, GPS/PES",
  "SPS/PSS" = "Social Democratic Party, SPS/PSS",
  "GLP/PVL" = "Green Liberal Party, GLP/PVL",
  "LDU" = "Ring of Independents, LdU/AdI",
  "CVP/PDC/PPD" = "Christian Democratic People's Party, CVP/PDC/PPD",
  "EVP/PEV" = "Evangelical People's Party, EVP/PEV",
  "CSP/PCS" = "Christian Social Party, CSP/PCS",
  # "LPS/PLS-FDP/PLR" = "FDP.The Liberals, LPS/PLS-FDP/PLR",
  "FDP/PLR" = "Free Democratic Party, FDP/PLR",
  "LPS/PLS" = "Liberal Party, LPS/PLS",
  "SVP/UDC" = "Swiss People's Party, SVP/UDC",
  "BDP/PBD" = "Conservative Democratic Party, BPD/PBD",
  "SLB/MSL" = "Social Liberal Movement, SLB/MSL", # not used, recoded as IND
  "FPS/PSL" = "Freedom Party, FPS/PSL",
  "EDU/UDF" = "Federal Democratic Union, EDU/UDF", # not used, recoded as IND
  "LEGA" = "Ticino League",
  "MCR/MCG" = "Geneva Citizens Movement, MCG/MCR",
  "IND" = "independent or minor party"
)

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
  # "LPS/PLS-FDP/PLR" = "#377EB8", # centre-right (LPS/PLS joined FDP/PLR), blue -- blue
  "FDP/PLR" = "#377EB8",         # centre-right Liberals (now FDP-The Liberals with LPS/PLS), blue -- blue
  "LPS/PLS" = "#053061",         # Liberals (now in FDP-The Liberals), dark blue -- dark blue
  "SVP/UDC" = "#00441B",         # rightwing, green -- very dark green
  "BDP/PBD" = "#FFFF33",         # centre-right, yellow -- yellow
  "SLB/MSL" = "#FF7F00",         # conservative, orange (not used) -- orange
  "FPS/PSL" = "#A65628",         # rightwing, brown -- brown
  "EDU/UDF" = "#C51B7D",         # Christian right, magenta (not used) -- magenta
  "LEGA" = "#80B1D3",            # Ticino League, regionalist, light blue -- light blue
  "MCR/MCG" = "#FF7F00",         # Mouvement Citoyens Romand, rightwing regionalist, yellow/red -- orange
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
  # "LPS/PLS-FDP/PLR" = 6.8,
  "FDP/PLR" = 6.3,
  "LPS/PLS" = 7.3,
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
