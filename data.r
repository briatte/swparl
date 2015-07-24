dir.create("raw/indexes"  , showWarnings = FALSE)
dir.create("raw/bills"    , showWarnings = FALSE)
dir.create("raw/sponsors" , showWarnings = FALSE)

legislatures = c(
  "1991-1995" = "1900-01-01", # l. 44 (baseline)
  "1995-1999" = "1995-10-22",
  "1999-2003" = "1999-10-24",
  "2003-2007" = "2003-10-19",
  "2007-2011" = "2007-10-21",
  "2011-2015" = "2011-10-23"  # l. 49
)

root = "http://www.parlament.ch/"
bills = "data/bills.csv"
sponsors = "data/sponsors.csv"

#
# download bills
#

if(!file.exists(bills)) {
  
  #
  # download indexes
  #
  
  for(k in 1:2) {
    
    for(l in 49:45) {
      
      i = 0
      
      f = paste0("raw/indexes/bills-", k, "-", l, "-", i, ".html")
      
      if(!file.exists(f))
        download.file(paste0(root, "f/suche/Pages/resultate.aspx?",
                             "collection=CV&gvk_gesch_erat_key=RAT_", k,
                             "_&gvk_gstate_key=ANY&gvk_gtyp_key=4&legislatur=", l,
                             "&sort=GN&way=desc"), f, mode = "wb", quiet = TRUE)
      
      p = html(f) %>%
        html_nodes(".search-pager a") %>% html_attr("href") %>%
        unique %>%
        gsub("(.*)from=(\\d+)&(.*)", "\\2", .) %>%
        as.integer
      
      cat("Indexing chamber", k, "legislature", l, "")
      
      while(i < p) {
        
        i = p
        
        f = paste0("raw/indexes/bills-", k, "-", l, "-", i, ".html")
        
        if(!file.exists(f))
          download.file(paste0(root, "f/suche/Pages/resultate.aspx?",
                               "from=", i, "&collection=CV&gvk_gesch_erat_key=RAT_", k,
                               "_&gvk_gstate_key=ANY&gvk_gtyp_key=4&legislatur=", l,
                               "&sort=GN&way=desc"), f, mode = "wb", quiet = TRUE)
        
        cat(".")
        
        p = html(f) %>%
          html_nodes(".search-pager a") %>% html_attr("href") %>%
          unique %>%
          gsub("(.*)from=(\\d+)&(.*)", "\\2", .) %>%
          as.integer
        
        p = max(p)
        
      }
      
      cat("\n")
      
    }
    
  }
  
  #
  # download bills (rerun in case of network errors)
  #
  
  p = list.files("raw/indexes", pattern = "^bills-", full.names = TRUE)
  
  d = data_frame()
  
  for(i in rev(p)) {
    
    cat("Page", which(p == i) %>% sprintf("%2.0f", .))
    
    h = html(i, encoding = "UTF-8") %>%
      html_nodes(".search-results a") %>%
      html_attr("href")
    
    d = rbind(d, data_frame(
      chamber = gsub("(.*)bills-(\\d)-(\\d{2})-(.*)", "\\2", i),
      legislature = gsub("(.*)bills-(\\d)-(\\d{2})-(.*)", "\\3", i),
      id = gsub("\\D", "", h)
    ))
    
    cat(": scraping", length(h), "bills ")
    
    for(j in h) {
      
      f = paste0("raw/bills/bill-", gsub("\\D", "", j), ".html")
      
      if(!file.exists(f))
        try(download.file(j, f, mode = "wb", quiet = TRUE))
      
      if(!file.info(f)$size) {
        
        cat("x")
        file.remove(f)
        
      } else {
        
        cat(".")
        
      }
      
    }
    
    cat("\n")
    
  }
  
  #
  # download bills (rerun in case of network errors)
  #
  
  p = list.files("raw/bills", pattern = "^bill-", full.names = TRUE)
  
  cat("Parsing", length(p), "bills...\n")
  
  b = data_frame()
  
  for(i in p) {
    
    h = html(i, encoding = "UTF-8")
    
    au = html_node(h, xpath = "//dd[@data-field='author-councillor']//a")
    co = html_nodes(h, "ul.mitunterzeichnende a") %>% html_attr("href")
    
    b = rbind(b, data_frame(
      id = gsub("\\D", "", i),
      date = html_node(h, xpath = "//dd[@data-field='deposit-date']") %>%
        html_text %>% strptime("%d.%m.%Y") %>% as.Date,
      title = html_node(h, "h3.cv-title") %>% html_text,
      au = ifelse(is.null(au), NA, html_attr(au, "href") %>% gsub("\\D", "", .)),
      co = ifelse(is.null(co), NA, paste0(gsub("\\D", "", co), collapse = ";"))
    ))
    
  }
  
  # remove bills with no authors
  b = filter(b, !is.na(au), au != "")
  
  # merge author and cosponsors
  b$sponsors = paste0(b$au, ";", b$co)
  b$sponsors = gsub(";$", "", b$sponsors)
  
  # count total number of sponsors
  b$n_au = 1 + str_count(b$sponsors, ";")
  
  # merge bills index and bills details
  b = inner_join(d, b, by = "id") %>% select(-au, -co)
  
  # convert legislature id to years
  b$legislature = names(legislatures)[ as.integer(b$legislature) - 43 ]
  
  # save to disk
  write.csv(b, bills, row.names = FALSE)
  
}

b = read.csv(bills, stringsAsFactors = FALSE)

#
# download sponsors
#

if(!file.exists(sponsors)) {
  
  cat("Downloading sponsor indexes...\n")
  
  h = GET("http://ws.parlament.ch/councillors/historic?lang=fr", accept_json()) %>%
    content("text") %>% fromJSON(flatten = TRUE)
  
  rownames(h) = NULL
  s = h
  
  i = 1
  
  while (!FALSE %in% h$hasMorePages) {
    
    i = i + 1
    
    h = GET(paste0("http://ws.parlament.ch/councillors/historic/",
                   "?lang=fr&pagenumber=", i), accept_json()) %>%
      content("text") %>% fromJSON(flatten = TRUE)
    
    rownames(h) = NULL
    s = rbind(s, h)
    
  }
  
  write.csv(s, "data/sponsors-full.csv", row.names = FALSE)
  
  # remove sponsor profiles for third chamber
  s = mutate(s, council.type = factor(council.type, levels = c("N", "S", "B"))
             %>% as.integer) %>%
    filter(council.type < 3)
  
  s$name = paste(s$firstName, s$lastName)
  s$sex = toupper(s$gender)
  s$born = substr(s$birthDate, 1, 4)
  s$start = as.Date(s$membership.entryDate)
  s$end = as.Date(s$membership.leavingDate)
  s$constituency = c(
    "AG" = "Aargau",
    "AI" = "Appenzell I.-Rh.",
    "AR" = "Appenzell A.-Rh.",
    "BE" = "Bern/Berne",
    "BL" = "Basel-Landschaft",
    "BS" = "Basel-Stadt",
    "FR" = "Freiburg/Fribourg",
    "GE" = "Genève",
    "GL" = "Glarus",
    "GR" = "Graubünden/Grigioni", # 2nd is Italian
    "JU" = "Jura",
    "LU" = "Luzern",
    "NE" = "Neuchâtel",
    "NW" = "Nidwalden",
    "OW" = "Obwalden",
    "SG" = "St. Gallen",
    "SH" = "Schaffhausen",
    "SO" = "Solothurn",
    "SZ" = "Schwyz",
    "TG" = "Thurgau",
    "TI" = "Ticino", # Italian
    "UR" = "Uri",
    "VD" = "Vaud",
    "VS" = "Wallis/Valais",
    "ZG" = "Zug",
    "ZH" = "Zürich"
  )[ s$canton.abbreviation ]
  
  # sanity check: all sponsors found in lower chamber
  a1 = strsplit(b$sponsors[ b$chamber == 1 ], ";") %>% unlist %>% unique
  stopifnot(a1 %in% s$id[ s$council.type == 1 ])
  
  # sanity check: all sponsors found in upper chamber
  a2 = strsplit(b$sponsors[ b$chamber == 2 ], ";") %>% unlist %>% unique
  stopifnot(a2 %in% s$id[ s$council.type == 2 ])
  
  # create unique chamber-level ids
  s$uid = paste(s$council.type, s$id)
  a1 = paste(1, as.integer(a1))
  a2 = paste(2, as.integer(a2))
  
  # subset to relevant sponsors of each chamber
  s = filter(s, uid %in% c(a1, a2)) %>%
    mutate(legislature = start) %>%
    select(legislature, id, chamber = council.type, name, sex, born,
           start, end, party = party.abbreviation, constituency)
  
  # find legislature id (closest start date)
  s$legislature = sapply(s$legislature, function(x) {
    x = x - as.Date(legislatures)
    names(legislatures)[ which.min(x[ x > 0 ]) ]
  })
  
  # find duration of each row (i.e. each party transition)
  s$end[ is.na(s$end) ] = Sys.Date()
  s$t = s$end - s$start
  
  # subset multiple party affiliations to longest one
  s = group_by(s, legislature, chamber, id) %>%
    mutate(longest = order(t, decreasing = TRUE)) %>%
    filter(longest == 1) %>%
    select(-start, -end, -t, -longest)
  
  # problem: some sponsors do not show up in their legislature
  # solution: append sponsors from the 2 previous legislatures
  for (i in unique(b$legislature)) {
    
    for (j in 1:2) {
      
      a = strsplit(b$sponsors[ b$legislature == i ], ";") %>% unlist
      m = a[ !a %in% s$id[ s$legislature == i ] ] %>% unique
      
      if (length(m) > 0) {
        
        y = names(legislatures)[ which(names(legislatures) == i) - j ]
        
        cat("Legislature", i, ": appending", length(m),
            "sponsor rows from legislature", y, "\n")
        
        m = filter(s, id %in% m, legislature == y)
        m$legislature = i
        s = rbind(group_by(s), m)
        
      }
      
    }
    
  }
  
  # check all sponsors are found
  for (i in unique(b$legislature)) {
    
    a = strsplit(b$sponsors[ b$legislature == i ], ";") %>% unlist
    m = a[ !a %in% s$id[ s$legislature == i ] ] %>% unique
    stopifnot(!m)
    
  }
  
  # check all sponsors are unique
  stopifnot(!duplicated(paste(s$legislature, s$chamber, s$id)))
  
  # compute seniority since l. 44
  s = arrange(s, id, chamber, legislature) %>%
    group_by(chamber, id) %>%
    mutate(nyears = 4 * 1:n() - 4)
  
  # drop l. 44 (not used in network construction)
  s = filter(s, legislature != "1991-1995")
  
  # party abbreviations and merges
  s$party = toupper(s$party)
  s$party[ s$party == "FRAP!" ] = "FRAP" # Christine Goll
  s$party[ s$party == "ADG" ] = "PDT" # Alternative de Gauche from Geneva
  s$party[ s$party %in% c("AL", "GB") ] = "PES" # Greens from Bern (GB) and Zoug (Al)
  s$party[ s$party %in% c("CSPO", "CSP-OW") ] = "PCS" # PCS from Obwald and Wallis
  
  # recodes based on JSON sponsor files
  # note: PBD created after legislature start date (explains coding as "-")
  s$party[ s$id == 167  ] = "FPS" # Massimo Pini, recoded from "Dém*"
  s$party[ s$id == 273  ] = "PBD" # Brigitta M. Gadient, recoded from "-"
  s$party[ s$id == 472  ] = "PBD" # Ursula Haller Vannini, recoded from "-"
  s$party[ s$id == 473  ] = "PBD" # Hansjörg Hassler, recoded from "-"
  s$party[ s$id == 3886 ] = "PBD" # Hans Grunder, recoded from "-"
  s$party[ s$id == 3918 ] = "PBD" # Werner Luginbühl, recoded from "-"
  s$party[ s$id == 4112 ] = "IND" # Thomas Minder, recoded from "-", truly unaffiliated
  
  # counts of parties at the individual level (both chambers combined)
  table(unique(select(s, id, party))$party, exclude = NULL)
  
  # simplification: parties at n == 1 in both chambers recoded to IND
  s$party[ s$party %in% c("-", "FRAP!") ] = "IND"
  
  # final counts of parties at the individual level
  table(unique(select(s, id, party))$party, exclude = NULL)
  table(s$party, s$legislature)
  
  # sanity check
  stopifnot(s$party %in% names(colors))
  
  write.csv(s, sponsors, row.names = FALSE)
  
}

s = read.csv(sponsors, stringsAsFactors = FALSE)

# download sponsor photos (rerun to fix network errors)

cat("Getting sponsor profiles and photos...\n")
for(i in unique(s$id)) {
  
  # step 1: download web profile
  f = paste0("raw/sponsors/mp-", i, ".html")
  
  if(!file.exists(f)) {
    
    try(download.file(paste0(root, "f/suche/Pages/biografie.aspx?biografie_id=", i),
                      f, quiet = TRUE, mode = "wb"), silent = TRUE)
    
  }
  
  if(!file.info(f)$size) {
    
    cat("Sponsor ID", sprintf("%3.0f", i), ": failed getting profile\n")
    file.remove(f)
    
  } else {
    
    # step 2: download photo
    u = html(f) %>%
      html_node(xpath = "//img[@class='profile']") %>% html_attr("src")
    
    f = paste0("photos/", i, ".jpg")
    if(!file.exists(f)) {
      
      try(download.file(paste0(root, u), f, quiet = TRUE, mode = "wb"),
          silent = TRUE)
      
    }
    
    if(!file.info(f)$size) {
      
      cat("Sponsor ID", sprintf("%3.0f", i), ": failed getting photo\n")
      file.remove(f)
      
    }
    
  }
  
}

# convert chamber ids to letters
b$chamber = c("cn", "cs")[ b$chamber ]
s$chamber = c("cn", "cs")[ s$chamber ]
