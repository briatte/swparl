# hi Switzerland

source("load.r")
source("functions.r")
source("parties.r")

# folders

dir.create("data"   , showWarnings = FALSE)
dir.create("photos" , showWarnings = FALSE)
dir.create("plots"  , showWarnings = FALSE)
dir.create("raw"    , showWarnings = FALSE)

# parameters

plot = TRUE
gexf = TRUE
mode = "fruchtermanreingold"
meta = c(
  "cty" = "Switzerland",
  "lang" = "fr", # Wikipedia language for chamber and constituencies
  "cn" = "Conseil_national_(Suisse)",
  "cs" = "Conseil_des_États_(Suisse)",
  "type-cn" = "Lower",
  "type-cs" = "Upper",
  "ipu-cn" = 2305,
  "ipu-cs" = 2306,
  "seats-cn" = 200,
  "seats-cs" = 46
)

# build routine

source("data.r")  # scrape bills and sponsors
source("build.r") # assemble the networks
source("comm.r")  # add committee co-membership

# have a nice day
