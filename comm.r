# add committee co-memberships

load("data/net_ch.rda")
comm = data.frame()

# find unique committees

for(i in dir("raw", pattern = "mp-\\d+\\.html$", full.names = TRUE)) {
  
  h = htmlParse(i, encoding = "UTF-8")
  l = xpathSApply(h, "//dd//a[contains(@href, 'kommissionen')]/@href")
  y = xpathSApply(h, "//dd//a[contains(@href, 'kommissionen')]/..", xmlValue)
  y = substr(str_clean(y), 1, 10)
  y = as.Date(strptime(y, "%d.%m.%Y"))
  y[ is.na(y) ] = as.Date("2014-01-01") # mandats actuels
  # n = xpathSApply(h, "//dd//a[contains(@href, 'kommissionen')]", xmlValue) # name (multilingual)
  comm = rbind(comm, data.frame(y, l, stringsAsFactors = FALSE))
  
}

comm$legislature = NA
comm$legislature[ comm$y <= as.Date("1995-10-22") ] = "1991-1995"
comm$legislature[ comm$y > as.Date("1995-10-22") & comm$y <= as.Date("1999-10-24") ] = "1995-1999"
comm$legislature[ comm$y > as.Date("1999-10-24") & comm$y <= as.Date("2003-10-19") ] = "1999-2003"
comm$legislature[ comm$y > as.Date("2003-10-19") & comm$y <= as.Date("2007-10-21") ] = "2003-2007"
comm$legislature[ comm$y > as.Date("2007-10-21") & comm$y <= as.Date("2011-10-23") ] = "2007-2011"
comm$legislature[ comm$y > as.Date("2011-10-23") & comm$y <= as.Date("2015-10-01") ] = "2011-2015" # l. 49

comm = unique(comm[, c("legislature", "l") ]) %>%
  arrange(legislature, l)

# unique legislature-committee pairs
comm = data.frame(uid = paste(comm$legislature, comm$l), stringsAsFactors = FALSE)

# add sponsor columns
for(i in dir("raw", pattern = "mp-\\d+\\.html$", full.names = TRUE))
  comm[, gsub("raw/mp-|\\.html", "", i) ] = 0

for(i in dir("raw", pattern = "mp-\\d+\\.html$", full.names = TRUE)) {
  
  h = htmlParse(i, encoding = "UTF-8")
  l = xpathSApply(h, "//dd//a[contains(@href, 'kommissionen')]/@href")
  y = xpathSApply(h, "//dd//a[contains(@href, 'kommissionen')]/..", xmlValue)
  y = substr(str_clean(y), 1, 10)
  y = as.Date(strptime(y, "%d.%m.%Y"))
  y[ is.na(y) ] = as.Date("2014-01-01") # mandats actuels
  
  z = NA
  z[ y <= as.Date("1995-10-22") ] = "1991-1995"
  z[ y > as.Date("1995-10-22") & y <= as.Date("1999-10-24") ] = "1995-1999"
  z[ y > as.Date("1999-10-24") & y <= as.Date("2003-10-19") ] = "1999-2003"
  z[ y > as.Date("2003-10-19") & y <= as.Date("2007-10-21") ] = "2003-2007"
  z[ y > as.Date("2007-10-21") & y <= as.Date("2011-10-23") ] = "2007-2011"
  z[ y > as.Date("2011-10-23") & y <= as.Date("2015-10-01") ] = "2011-2015" # l. 49
  
  y = paste(z, l)
  comm[ comm$uid %in% y, names(comm) == gsub("raw/mp-|\\.html", "", i) ] = 1
  
}

# save flat list

write.csv(cbind(legislature = substr(comm$uid, 1, 9), 
                url = substring(comm$uid, first = 11), 
                members = rowSums(comm[, -1:-2 ])),
          "data/committees.csv", row.names = FALSE)

# assign co-memberships to networks
comm$legislature = substr(comm$uid, 1, 4)
for(i in unique(comm$legislature)) {
  
  cat("Legislature", i)
  
  n = get(paste0("net_ch", i))
  sp = network.vertex.names(n)
  
  names(sp) = n %v% "url"
  
  m = comm[ comm$legislature == i, names(comm) %in% names(sp) ]
  cat(":", nrow(m), "committees", ncol(m), "MPs")
  M = m
  
  m = t(as.matrix(m)) # sponsors in rows, committees in columns
  m = m %*% t(m) # adjacency matrix
  
  colnames(m) = sp[ colnames(m) ]
  rownames(m) = sp[ rownames(m) ]
  
  
  e = data.frame(i = n %e% "source", 
                 j = n %e% "target", 
                 stringsAsFactors = FALSE)
  e$committee = NA
  
  for(j in 1:nrow(e))
    e$committee[ j ] = m[ e$i[ j ], e$j[ j ] ]
  
  cat(" co-memberships:", 
      str_pad(paste0(range(e$committee), collapse = "-"), 6, "right"), 
      sum(e$committee == 0), "null,", 
      sum(e$committee == 1), "single,",
      sum(e$committee > 1), "> 1\n")
  
  nn = network(e[, 1:2], directed = FALSE)
  nn %e% "committee" = e$committee
  
  print(table(nn %e% "committee", exclude = NULL))
  stopifnot(!is.na(nn %e% "committee"))
  
  n %e% "committee" = e$committee
  assign(paste0("net_ch", i), n)
  
  nn %n% "committees" = as.table(rowSums(M))
  assign(paste0("conet_ch", i), nn)

}

save(list = ls(pattern = "^((co)?net|edges|bills)_ch\\d{4}$"),
     file = "data/net_ch.rda")
