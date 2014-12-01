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
          
          outcome[ outcome == j ] = scrubber(xpathSApply(h, "//dd[@data-field='state']", xmlValue))
          
          t = xpathSApply(h, "//ul[@class='linklist services']/li/a[contains(@href, 'kommissionen')]", xmlValue)
          commissions[ commissions == j ] = paste0(scrubber(t), collapse = ";")
          
          # this syntax will not match commission-authored proposals
          t = xpathSApply(h, "//ul[@class='profilelist small']/li/a/@href")
          authors[ authors == j ] = paste0(t, collapse = ";")
          
          t = xpathSApply(h, "//ul[@class='linklist mitunterzeichnende']/li/a/@href")
          cosponsors[ cosponsors == j ] = paste0(t, collapse = ";")
          
          t = xpathSApply(h, "//div[@class='curia-vista-tags contentelement']/ul/li/a", xmlValue)
          keywords[ keywords == j ] = paste0(scrubber(t), collapse = ";")
          
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
      
      name = scrubber(xpathSApply(h, "//h1", xmlValue))
      photo = xpathSApply(h, "//img[@class='profile']/@src")
      constituency = xpathSApply(h, "//img[@class='canton']/@alt")
      
      born = scrubber(xpathSApply(h, "//dl[@class='services'][1]/dd[1]", xmlValue))
      born = str_extract(born, "[0-9]{4}")
      
      mandate = xpathSApply(h, "//ul[@class='council']/li[@class='rat']/following-sibling::li[1]", xmlValue)
      mandate = paste0(mandate, collapse = " ")
      party = scrubber(xpathSApply(h, "//ul[@class='linklist party']/li", xmlValue))
      
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

# simplify photo URL
s$photo = gsub("photos/|\\.jpg", "", s$photo)

# fix names
s$name = gsub("^de\\s", "de_", s$name)
s$name = gsub("^von\\s", "von_", s$name)
s$name = gsub("^van\\s", "van_", s$name)
s$name = sapply(s$name, function(x) {
  x = unlist(strsplit(x, " "))
  return(paste(paste0(x[-1], collapse = " "), x[1]))
})
s$name = gsub("de_", "de ", s$name)
s$name = gsub("von_", "von ", s$name)
s$name = gsub("van_", "van ", s$name)

# final name bugfixes
s$name[ s$name == "Schüttel Ursula Schneider" ] = "Ursula Schneider Schüttel"
s$name[ s$name == "Goumaz Adèle Thorens" ] = "Adèle Thorens Goumaz"
s$name[ s$name == "Graf Martine Brunschwig" ] = "Martine Brunschwig Graf"
s$name[ s$name == "Vannini Ursula Haller" ] = "Ursula Haller Vannini"
s$name[ s$name == "Wyss Pascale Bruderer" ] = "Pascale Bruderer Wyss"
s$name[ s$name == "J. Alexander Baumann" ] = "Alexander Baumann" # removed initial
s$name[ s$name == "d'Epinay Maya Lalive" ] = "Maya Lalive d'Epinay"
s$name[ s$name == "Pasquier Liliane Maury" ] = "Liliane Maury Pasquier"
s$name[ s$name == "Schoch Regina Ammann" ] = "Regina Ammann Schoch"
s$name[ s$name == "Schüttel Ursula Schneider" ] = "Ursula Schneider Schüttel"

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
s$partyname[ is.na(s$partyname) ] = "IND" # undefined party affiliation

# party abbreviations
s$party = s$partyname
s$party = gsub("(.*)\\s\\((.*)\\)", "\\2", s$party) # use abbreviations only
s$party[ grepl("SVP|UDC", s$party) ] = "SVP/UDC" # 
s$party[ grepl("SP(S)?|PSS", s$party) ] = "SPS/PSS" # 
s$party[ grepl("LPS|PLS|FDP|PLR", s$party) ] = "LPS/PLS-FDP/PLR" # 
s$party[ grepl("CVP|PDC|PPD", s$party) ] = "CVP/PDC/PPD" # 
s$party[ grepl("BDP|PBD", s$party) ] = "BDP/PBD" # 
s$party[ grepl("GPS|PES|GB", s$party) ] = "GPS/PES/GB" # 
s$party[ grepl("GLP|glp|PVL|pvl", s$party) ] = "GLP/PVL" # 
s$party[ grepl("EVP|PEV", s$party) ] = "EVP/PEV" # 
s$party[ grepl("CSP(O)?|PCS|csp-ow", s$party) ] = "CSP/PCS" # 
s$party[ grepl("Lega", s$party) ] = "LEGA" # 
s$party[ grepl("EDU|UDF", s$party) ] = "EDU/UDF" # 
s$party[ grepl("AL|LG", s$party) ] = "AL/LG" # 
s$party[ grepl("SLB|MSL", s$party) ] = "SLB/MSL" # 
s$party[ grepl("LdU", s$party) ] = "LDU" # 
s$party[ grepl("MCR|MCG", s$party) ] = "MCR/MCG" # 
s$party[ grepl("PdT|PdA", s$party) ] = "PDA/PST" # 
s$party[ grepl("FPS|PSL", s$party) ] = "FPS/PSL" # 
table(s$party, exclude = NULL)

# party translations (English, except one regionalist with French name only)

s$partyname[ s$party == "SVP/UDC" ] = "Swiss People's Party, SVP/UDC"
s$partyname[ s$party == "SPS/PSS" ] = "Social Democratic Party, SPS/PSS"
s$partyname[ s$party == "LPS/PLS-FDP/PLR" ] = "FDP.The Liberals, LPS/PLS-FDP/PLR"
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

# final simplification: parties at n < 3 among sponsors recoded to IND/MIN
s$party[ s$party %in% c("AL/LG", "CSP/PCS", "EDU/UDF", "LDU", "MCR/MCG", "PDA/PST", "SLB/MSL") ] = "IND"
s$partyname[ s$party == "IND" ] = "independent or minor party"


s$sex = NA
# fn = sapply(s$name[ is.na(s$sex) ], function(x) unlist(strsplit(x, " "))[1])
# sort(unique(fn))

s$sex[ grepl("^(Ada\\s|Adèle|Agnes|Alice|Aline|Andrea Martina|Angeline|Anita|Anne|Barbara|Bea\\s|Brigit(tta|tte)?|Cécile|Céline|Cesla|Chantal|Chiara|Christa|Christiane|Christine|Claudia|Corina|Daniela|Doris|Dorle|Edith|Elisabeth|Elvira|Emmanuella|Erika|Esther|Eva\\s|Evi\\s|Fabienne|Francine|Françoise|Franziska|Gabi\\s|Geneviève|Géraldine|Gisèle|Helen|Hildegard|Ida\\s|Isabelle|Jacqueline|Jasmin|Josiane|Judith|Kälin|Karin|Katharina|Käthi|Kathrin|Kathy|Laura|Lenz|Lili(\\s|ane)|Lisbeth|Lucrezia|Madeleine|Maja|Margrit|Marguerite|Maria(\\s|nne)|Marie-Thérèse|Marlies|Martin(a|e)|Maya|Michèle-Irène|Milli|Monika|Nadine|Nadja|Natalie|Nellen|Pascale|Petra|Pia\\s|Planta|Prisca|Rebecca|Regin(a|e)|Regula|Roberta|Rose-Marie|Ros(e)?marie|Ruth|Silv(i)?a|Simonetta|Stephanie|Susanna|Suzette|Sylvi(a|e)|Therese|Thérèse|Tiana|Trix|Ursula|Valérie|Verena|Viola|Vreni|Yv(ette|onne))", s$name) ] = "F"
# checked: all Claudes are males
s$sex[ grepl("^(Adalbert|Adrian(o)?|Alain|Albert|Albrecht|Alec|Alex(\\s|ander|is)|Alfred|Allmen|Alois|André|Andrea(s)?|Andy|Anton|Armin|Arthur|Attilio|Balthasar|Bastien|Beat|Béguelin|Bern(h)?ard|Boris|Bruno|Carlo|Carrard|Caspar|Cédric|Charles|Christian\\s|Christoffel|Christoph(\\s|e)|Claude\\s|Corrado|Cyrill|Daniel\\s|Dick|Didier|Dominique (Baettig|de Buman)|Dumeni|Duri\\s|Edgar|Edi\\s|Edouard|Elmar|Eric(\\s|h)|Ernst|Erwin|Eugen|Fabio|Fathi|Felix|Fernand\\s|Filippo|Flavio|Francis\\s|Franco|François\\s|Franz\\s|Franz-Joseph|Fredi|Fritz|Fulvio|Gabriel(\\s|e)|Georg(\\s|es)|Gerhard|Geri\\s|Gerold|Gian-Reto|Gilbert|Giorgio|Giovanni|Giuliano|Gregor|Guido|Guillaume|Guscetti|Guy\\s|Hannes|Hans(-|\\s|j|p|ruedi|ueli|heiri)|Heiner|Heinrich|Heinz|Helmut|Herbert|Hermann|Hubert|Hugo|Hugues|Ignazio|Isidor|Ivo\\s|Jacques|Jakob|Jean(\\s|-)|Joachim|Johann(\\s|es)|John|Josef|Joseph|Josias|Jost|Jürg|Karl|Kaspar|Konrad|Kurt|Laurent|Lieni|Leo\\s|Lorenz(\\s|o)|Lothar|Louis|Luc\\s|Lukas|Luzi|Manfred|Manuel\\s|Marc(\\s|el\\s|o\\s)|Mario|Markus|Martin\\s|Massimo|Ma(t)?thias|Maurice|Mauro|Max(\\s|imilian)|Meinrado|Melchior|Michael\\s|Michel|Moritz|Niklaus|Norbert|Norman|Oberholzer|Odilo|Olivier|Os(c|k)ar|Oswald|Otto|Pankraz|Pascal\\s|Patrice|Paul\\s|Paul-André|Peter\\s|Peter-Josef|Philipp(\\s|e)|Pierre|Pirmin|Pius|Raphaël\\s|Raymond|Reinhard|Remigio|Remo|Rémy|René\\s|Renzo|Reto\\s|Ricardo|Rico\\s|Robert(\\s|o)|Roger|Roland|Rolf|Rotz|Rudolf|Ruedi|Samuel\\s|Sebastian|Sep\\s|Serg(e|io)|Simon\\s|Stefan\\s|Stéphane|Tarzisius|Theo(\\s|dor|phil)|Thierry|This|Thomas|Titus|Toni\\s|Ueli|Ulrich|Urs\\s|Victor\\s|Vital|Walter|Werner|Wilfried|Willi(\\s|am)|Willy|Yannick|Yv(an|es))", s$name) ] = "M"

s[ is.na(s$sex) & !is.na(s$photo), c("name", "photo") ]

# kthxbye
