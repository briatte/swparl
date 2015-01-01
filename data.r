root = "http://www.parlament.ch"
bills = "data/bills.csv"
sponsors = "data/sponsors.csv"

# scrape bills

if(!file.exists(bills)) {
  
  # scraping only legislative initiatives (initiatives parlementaires)
  # leaving out nonbinding resolutions (motions)
  l = htmlParse(root, "/f/suche/Pages/resultate.aspx?collection=CV&gvk_gstate_key=ANY&gvk_gtyp_key=4&sort=GN&way=desc", 
                encoding = "UTF-8")
  
  l = xpathSApply(l, "//span[@class='numresults'][1]", xmlValue)
  l = seq(1, as.numeric(gsub("\\D", "", l)), by = 25) # ~ 2200 bills
  
  b = data.frame()
  
  # rerun a couple of times to solve network errors
  for(i in rev(l)) {
    cat(sprintf("%2.0f", which(l == i)), "Scraping page", sprintf("%4.0f", i))
    
    file = paste0("raw/bills-", i, ".html")
    
    if(!file.exists(file))
      download.file(paste0(root, "/f/suche/Pages/resultate.aspx?from=", i, 
                           "&collection=CV&gvk_gstate_key=ANY&gvk_gtyp_key=4&sort=GN&way=desc"), 
                    file, quiet = TRUE, mode = "wb")
    
    h = htmlParse(file, encoding = "UTF-8")
    
    url = xpathSApply(h, "//ol[@class='search-results']/li/h2/a/@href")
    summary = xpathSApply(h, "//ol[@class='search-results']/li/h2", xmlValue)
    description = xpathSApply(h, "//ol[@class='search-results']/li/p[1]", xmlValue)
    answer = xpathSApply(h, "//ol[@class='search-results']/li/span[1]", xmlValue)
    status = xpathSApply(h, "//ol[@class='search-results']/li/span[1]", xmlValue)
    
    file = title = subtitle = date = council = outcome = commissions = authors = cosponsors = keywords = url
    for(j in url) {
      
      if(grepl("gesch_id", j))
        f = gsub("(.*)gesch_id=(\\d+)", "raw/bill-\\2.html", j)
      else
        f = gsub("(.*)f_gesch_(\\d+)(.*)", "raw/bill-\\2.html", j)
      
      if(!file.exists(f))
        download.file(j, f, quiet = TRUE, mode = "wb")
      
      if(!file.info(f)$size)
        file.remove(f)
      
      if(file.exists(f)) {
        
        h = htmlParse(f, encoding = "UTF-8")
        file[ file == j ] = f
        
        t = xpathSApply(h, "//h2[@class='cv-title']", xmlValue)
        
        # recent pages
        if(length(t)) {
          
          cat(".")
          
          title[ title == j ] = t
          subtitle[ subtitle == j ] = xpathSApply(h, "//h3[@class='cv-title']", xmlValue)
          
          t = xpathSApply(h, "//dd[@data-field='deposit-date']", xmlValue)
          date[ date == j ] = ifelse(length(t), t, NA)
          
          t = xpathSApply(h, "//dd[@data-field='deposit-council']", xmlValue)
          council[ council == j ] = ifelse(length(t), t, NA)
          
          outcome[ outcome == j ] = str_clean(xpathSApply(h, "//dd[@data-field='state']", xmlValue))
          
          t = xpathSApply(h, "//ul[@class='linklist services']/li/a[contains(@href, 'kommissionen')]", xmlValue)
          commissions[ commissions == j ] = paste0(str_clean(t), collapse = ";")
          
          # this syntax will not match commission-authored proposals
          t = xpathSApply(h, "//ul[@class='profilelist small']/li/a/@href")
          authors[ authors == j ] = paste0(t, collapse = ";")
          
          t = xpathSApply(h, "//ul[@class='linklist mitunterzeichnende']/li/a/@href")
          cosponsors[ cosponsors == j ] = paste0(t, collapse = ";")
          
          t = xpathSApply(h, "//div[@class='curia-vista-tags contentelement']/ul/li/a", xmlValue)
          keywords[ keywords == j ] = paste0(str_clean(t), collapse = ";")
          
        } else {
          
          cat("_")
          title = subtitle = date = council = outcome = commissions = authors = cosponsors = keywords = NA
          
        }
        
      } else {
        
        cat("x")
        
      }
      
    }
    
    f[ !grepl("^raw/", f) ] = NA
    
    b = rbind(b, data.frame(url, file, summary, description, answer, status, 
                            title, subtitle, date, council, outcome, 
                            commissions, authors, cosponsors, keywords,
                            stringsAsFactors = FALSE))
    
    cat(":", sprintf("%4.0f", nrow(b)), "total bills\n")
    
  }
  
  b$n_au = 1 + str_count(b$authors, ";")
  b$n_au[ is.na(b$authors) ] = NA
  b$n_au[ b$authors == "" ] = 0
  
  b$n_co = 1 + str_count(b$cosponsors, ";")
  b$n_co[ is.na(b$cosponsors) ] = NA
  b$n_co[ b$cosponsors == "" ] = 0
  
  b$n_a = b$n_au + b$n_co
  
  b$date = as.Date(strptime(b$date, "%d.%m.%Y"))
  b$legislature = NA
  b$legislature[ b$date <= as.Date("1995-10-22") ] = "1991-1995"
  b$legislature[ b$date > as.Date("1995-10-22") & b$date <= as.Date("1999-10-24") ] = "1995-1999"
  b$legislature[ b$date > as.Date("1999-10-24") & b$date <= as.Date("2003-10-19") ] = "1999-2003"
  b$legislature[ b$date > as.Date("2003-10-19") & b$date <= as.Date("2007-10-21") ] = "2003-2007"
  b$legislature[ b$date > as.Date("2007-10-21") & b$date <= as.Date("2011-10-23") ] = "2007-2011"
  b$legislature[ b$date > as.Date("2011-10-23") & b$date <= as.Date("2015-10-01") ] = "2011-2015" # l. 49
  
  print(table(b$n_a > 1, b$legislature, exclude = NULL))
  write.csv(b, bills, row.names = FALSE)

}

b = read.csv(bills, stringsAsFactors = FALSE)

# scrape sponsors

if(!file.exists(sponsors)) {
  
  a = c(unlist(strsplit(b$authors, ";")), unlist(strsplit(b$cosponsors, ";")))
  a = unique(na.omit(a))
  
  s = data.frame()
  for(i in rev(a)) {
    
    cat(sprintf("%3.0f", which(a == i)), i)
    f = gsub("(.*)biografie_id=(\\d+)", "raw/mp-\\2.html", i)
    
    if(!file.exists(f))
      download.file(paste0(root, i), f, quiet = TRUE, mode = "wb")
    
    if(!file.info(f)$size)
      file.remove(f)
    
    if(file.exists(f)) { 
      
      h = htmlParse(f, encoding = "UTF-8")
      
      name = str_clean(xpathSApply(h, "//h1", xmlValue))
      photo = xpathSApply(h, "//img[@class='profile']/@src")
      constituency = xpathSApply(h, "//img[@class='canton']/@alt")
      
      born = str_clean(xpathSApply(h, "//dl[@class='services'][1]/dd[1]", xmlValue))
      born = str_extract(born, "[0-9]{4}")
      
      mandate = xpathSApply(h, "//ul[@class='council']/li[@class='rat']/following-sibling::li[1]", xmlValue)
      mandate = paste0(mandate, collapse = " ")
      party = str_clean(xpathSApply(h, "//ul[@class='linklist party']/li", xmlValue))
      
      groupname = ifelse(length(party) == 2, party[1], NA)
      partyname = ifelse(!length(party), NA, party)
      partyname = ifelse(length(party) == 2, party[2], party)
      
      s = rbind(s, data.frame(url = i, name, born, groupname, partyname,
                              constituency, mandate, photo, stringsAsFactors = FALSE))
      cat(":", name, "\n")
      
    } else {
      
      cat("x\n")
      
    }
    
  }
  
  # download photos
  
  p = na.omit(unique(s$photo))
  
  # rerun a few times to solve network issues
  for(i in rev(p)) {
    
    f = gsub("(.*)gross/(.*)", "photos/\\2", i)
    cat(sprintf("%3.f", which(p == i)), "Photo", i, f)
    
    if(!file.exists(f))
      try(download.file(paste0(root, i), f, quiet = TRUE, mode = "wb"), silent = TRUE)
    
    if(!file.info(f)$size)
      file.remove(f)
    
    if(file.exists(f)) {
      s$photo[ s$photo == i ] = f
      cat(": OK\n")
    } else {
      s$photo[ s$photo == i ] = NA
      cat(": failed\n")
    }
    
  }
  
  write.csv(s, sponsors, row.names = FALSE)
  
}

# parse sponsors

s = read.csv(sponsors, stringsAsFactors = FALSE)

# constituency to acronym (not used in order to pass full name to GEXF export)
# s$constituency = gsub("(.*)\\((\\w+)\\)", "\\2", s$constituency)

# simplify photo URL
s$photo = gsub("photos/|\\.jpg", "", s$photo)

# fix names (most middle words are first names)
s$name = gsub("(^|\\s|-)(de|v(a|o)n)\\s", "\\1\\2_", s$name)
s$name = sapply(s$name, function(x) {
  x = unlist(strsplit(x, " "))
  return(paste(paste0(x[-1], collapse = " "), x[1]))
})
s$name = gsub("_", " ", s$name)

# final name bugfixes
s$name[ s$name == "Béguelin Marlyse Dormond" ] = "Marlyse Dormond Béguelin"
s$name[ s$name == "Bonetti Mimi Lepori" ] = "Mimi Lepori Bonetti"
s$name[ s$name == "Carrard Valérie Piller" ] = "Valérie Piller Carrard"
s$name[ s$name == "d'Epinay Maya Lalive" ] = "Maya Lalive d'Epinay"
s$name[ s$name == "Goumaz Adèle Thorens" ] = "Adèle Thorens Goumaz"
s$name[ s$name == "Graf Martine Brunschwig" ] = "Martine Brunschwig Graf"
s$name[ s$name == "Guscetti Marina Carobbio" ] = "Marina Carobbio Guscetti"
s$name[ s$name == "J. Alexander Baumann" ] = "Alexander Baumann" # removed initial
s$name[ s$name == "Kälin Barbara Marty" ] = "Barbara Marty Kälin"
s$name[ s$name == "Lenz Verena Diener" ] = "Verena Diener Lenz"
s$name[ s$name == "Nellen Margret Kiener" ] = "Margret Kiener Nellen"
s$name[ s$name == "Oberholzer Susanne Leutenegger" ] = "Susanne Leutenegger Oberholzer"
s$name[ s$name == "Pasquier Liliane Maury" ] = "Liliane Maury Pasquier"
s$name[ s$name == "Schoch Regina Ammann" ] = "Regina Ammann Schoch"
s$name[ s$name == "Schüttel Ursula Schneider" ] = "Ursula Schneider Schüttel"
s$name[ s$name == "Vannini Ursula Haller" ] = "Ursula Haller Vannini"
s$name[ s$name == "Wyss Pascale Bruderer" ] = "Pascale Bruderer Wyss"

# mandate years
s$mandate = sapply(s$mandate, function(x) {
  x = as.numeric(unlist(str_extract_all(x, "[0-9]{4}")))
  if(length(x) %% 2 == 1)
    x = c(x, 2014)
  x = matrix(x, ncol = 2, byrow = TRUE)   # each row is a term
  x = apply(x, 1, paste0, collapse = "-") # each value is a sequence
  x = lapply(x, function(x) {
    x = as.numeric(unlist(strsplit(x, "-")))
    x = seq(x[1], x[2])
  })
  paste0(sort(unique(unlist(x))), collapse = ";") # all years included in mandate(s)
})

# duplicate names
s$name[ s$url == "/f/suche/pages/biografie.aspx?biografie_id=79" ] = "Theo Fischer-2"
s$name[ s$url == "/f/suche/pages/biografie.aspx?biografie_id=80" ] = "Theo Fischer-1"

# party simplifications
s$partyname[ grepl("Alternative Kanton Zug", s$partyname) ] = "GPS" # same federation (n = 1)
s$partyname[ grepl("Alliance jurassienne|parteilos", s$partyname) ] = "IND" # n = 1 each
s$partyname[ is.na(s$partyname) ] = "IND" # undefined party affiliation (many)

# party abbreviations
s$party = s$partyname
s$party = gsub("(.*)\\s\\((.*)\\)", "\\2", s$party) # use abbreviations only
s$party[ s$party %in% c("SVP", "UDC") ] = "SVP/UDC" # 
s$party[ s$party %in% c("SP", "PSS") ] = "SPS/PSS" # 
s$party[ s$party %in% c("LPS", "PLS", "FDP-Liberale", "PLR") ] = "LPS/PLS-FDP/PLR" # Liberals + FDP
# s$party[ s$party %in% c("LPS", "PLS") ] = "LPS/PLS" # Liberals
# s$party[ s$party %in% c("FDP-Liberale", "PLR") ] = "FDP/PLR" # FDP
s$party[ s$party %in% c("CVP", "PDC", "PPD") ] = "CVP/PDC/PPD" # 3rd acronym is Italian
s$party[ s$party %in% c("BDP", "PBD") ] = "BDP/PBD" # PBD not used
s$party[ s$party %in% c("GPS", "PES", "GB") ] = "GPS/PES/GB" # includes Greens from Bern, GB
s$party[ s$party %in% c("glp", "PVL", "pvl") ] = "GLP/PVL" # PVL not used
s$party[ s$party %in% c("EVP", "PEV") ] = "EVP/PEV" # PEV not used
s$party[ s$party %in% c("CSP", "CSPO", "PCS", "csp-ow") ] = "CSP/PCS" # PCS not used
s$party[ s$party %in% c("Lega") ] = "LEGA" # 
s$party[ s$party %in% c("EDU", "UDF") ] = "EDU/UDF" # UDF not used
s$party[ s$party %in% c("AL", "LG") ] = "AL/LG" # AL not used
s$party[ s$party %in% c("SLB", "MSL") ] = "SLB/MSL" # SLB not used
s$party[ s$party %in% c("LdU") ] = "LDU" # 
s$party[ s$party %in% c("MCR", "MCG") ] = "MCR/MCG" # MCG not used
s$party[ s$party %in% c("PdT", "PdA") ] = "PDA/PST" # PdA not used
s$party[ s$party %in% c("FPS", "PSL") ] = "FPS/PSL" # PSL not used
table(s$party, exclude = NULL)

# party translations (English, except one regionalist with French name only)

s$partyname[ s$party == "SVP/UDC" ] = "Swiss People's Party, SVP/UDC"
s$partyname[ s$party == "SPS/PSS" ] = "Social Democratic Party, SPS/PSS"
s$partyname[ s$party == "LPS/PLS-FDP/PLR" ] = "FDP.The Liberals, LPS/PLS-FDP/PLR"
# s$partyname[ s$party == "LPS/PLS" ] = "Liberal Party, LPS/PLS"
# s$partyname[ s$party == "FDP/PLR" ] = "FDP.The Liberals, FDP/PLR"
s$partyname[ s$party == "CVP/PDC/PPD" ] = "Christian Democratic People's Party, CVP/PDC/PPD"
s$partyname[ s$party == "BDP/PBD" ] = "Conservative Democratic Party, BPD/PBD"
s$partyname[ s$party == "GPS/PES/GB" ] = "Green Party, GPS/PES"
s$partyname[ s$party == "GLP/PVL" ] = "Green Liberal Party, GLP/PVL"
s$partyname[ s$party == "EVP/PEV" ] = "Evangelical People's Party, EVP/PEV"
s$partyname[ s$party == "CSP/PCS" ] = "Christian Social Party, CSP/PCS"
s$partyname[ s$party == "LEGA" ] = "Ticino League"
s$partyname[ s$party == "LDU" ] = "Ring of Independents, LdU/AdI"
s$partyname[ s$party == "EDU/UDF" ] = "Federal Democratic Union, EDU/UDF"
s$partyname[ s$party == "AL/LG" ] = "Alternative Left, AL/LG/LS"
s$partyname[ s$party == "SLB/MSL" ] = "Social Liberal Movement, SLB/MSL"
s$partyname[ s$party == "MCR/MCG" ] = "Mouvement Citoyens Genevois/Romand, MCG/MCR"
s$partyname[ s$party == "PDA/PST" ] = "Swiss Party of Labour, PdA/PST"
s$partyname[ s$party == "FPS/PSL" ] = "Freedom Party, FPS/PSL"

# final simplification: parties at n < 2 in all networks recoded to IND/MIN
s$party[ s$party %in% c("AL/LG", "EDU/UDF", "PDA/PST", "SLB/MSL") ] = "IND"

s$partyname[ s$party == "IND" ] = "independent or minor party"

s$sex = NA
# fn = sapply(s$name[ is.na(s$sex) ], function(x) unlist(strsplit(x, " "))[1])
# sort(unique(fn))

# checked: no female/male overlap between the regex
s$sex[ grepl("^(Ada\\s|Adèle|Agnes|Alice|Aline|Angeline|Anita|Anne|Barbara|Bea\\s|Brigit(tta|tte)?|Cécile|Céline|Cesla|Chantal|Chiara|Christa|Christiane|Christine|Claudia|Corina|Daniela|Doris|Dorle|Edith|Elisabeth|Elvira|Emmanuella|Erika|Esther|Eva\\s|Evi\\s|Fabienne|Francine|Françoise|Franziska|Gabi\\s|Geneviève|Geo\\s|Géraldine|Gisèle|Helen|Hildegard|Ida\\s|Isabelle|Jacqueline|Jasmin|Josiane|Josy|Judith|Kälin|Karin|Katharina|Käthi|Kathrin|Kathy|Laura|Len(i|z)|Lili(\\s|ane)|Lisbeth|Lucrezia|Madeleine|Maja|Margrit|Marguerite|Maria(\\s|nne)|Marie-Thérèse|Mar(ina|gret)|Marl(ies|yse)|Martin(a|e)|Maya|Menga|Michèle-Irène|Milli|Mimi|Monika|Nadine|Nadja|Natalie|Nellen|Pascale|Petra|Pia\\s|Planta|Prisca|Rebecca|Regin(a|e)|Regula|Roberta|Rose-Marie|Ros(e)?marie|Ruth|Silv(i)?a|Simonetta|Stephanie|Susann(a|e)|Suzette|Sylvi(a|e)|Therese|Thérèse|Tiana|Trix|Ursula|Valérie|Verena|Viola|Vreni|Yv(ette|onne))", s$name) ] = "F"

# checked: all Claudes are males
s$sex[ grepl("^(Adalbert|Adrian(o)?|Alain|Albert|Albrecht|Alec|Alex(\\s|ander|is)|Alfred|Allmen|Alois|André|Andrea(s)?|Andy|Anton|Armin|Arthur|Attilio|Balthasar|Bastien|Beat|Béguelin|Bern(h)?ard|Boris|Bruno|Carlo|Carrard|Caspar|Cédric|Charles|Christian\\s|Christoffel|Christoph(\\s|e)|Claude\\s|Corrado|Cyrill|Daniel\\s|Dick|Didier|Dominique (Baettig|de Buman)|Dumeni|Duri\\s|Edgar|Edi\\s|Edouard|Elmar|Eric(\\s|h)|Ernst|Erwin|Eugen|Fabio|Fathi|Felix|Fernand\\s|Filippo|Flavio|Francis\\s|Franco|François\\s|Franz\\s|Franz-Joseph|Fredi|Fritz|Fulvio|Gabriel(\\s|e)|Georg(\\s|es)|Gerhard|Geri\\s|Gerold|Gian-Reto|Gilbert|Giorgio|Giovanni|Giuliano|Gregor|Guido|Guillaume|Guscetti|Guy\\s|Hannes|Hans(-|\\s|j|p|ruedi|ueli|heiri)|Hardi|Heiner|Heinrich|Heinz|Helmut|Herbert|Hermann|Hubert|Hugo|Hugues|Ignazio|Isidor|Ivo\\s|Jacques|Jakob|Jean(\\s|-)|Joachim|Johann(\\s|es)|John|Josef|Joseph|Josias|Jost|Jürg|Karl|Kaspar|Konrad|Kurt|Laurent|Lieni|Leo\\s|Lorenz(\\s|o)|Lothar|Louis|Luc\\s|Lukas|Luregn|Luzi|Manfred|Manuel\\s|Marc(\\s|el\\s|o\\s)|Mario|Markus|Martin\\s|Massimo|Ma(t)?thias|Maurice|Mauro|Max(\\s|imilian)|Meinrado|Melchior|Michael\\s|Michel|Moritz|Niklaus|Norbert|Norman|Oberholzer|Odilo|Olivier|Os(c|k)ar|Oswald|Otto|Pankraz|Pascal\\s|Patrice|Paul\\s|Paul-André|Peter\\s|Peter-Josef|Philipp(\\s|e)|Pierre|Pirmin|Pius|Raphaël\\s|Raymond|Reinhard|Remigio|Remo|Rémy|René\\s|Renzo|Reto\\s|Ricardo|Rico\\s|Robert(\\s|o)|Roger|Roland|Rolf|Rotz|Rudolf|Ruedi|Samuel\\s|Sebastian|Sep\\s|Serg(e|io)|Simon\\s|Stefan\\s|Stéphane|Tarzisius|Theo(\\s|dor|phil)|Thierry|This|Thomas|Titus|Toni\\s|Ueli|Ulrich|Urs\\s|Victor\\s|Vital|Walter|Werner|Wilfried|Willi(\\s|am)|Willy|Yannick|Yv(an|es))", s$name) ] = "M"

s$sex[ s$name == "Dominique Ducret" ] = "M" # checked
s$sex[ s$name == "Andrea Martina Geissbühler" ] = "F" # recoded as male by regex

# kthxbye
