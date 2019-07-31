library(httr)
library(jsonlite)
library(readr)

url <- "https://server.matters.news/graphql/"
GQL <- function(query, .url = url){
  pbody <- list(query = query)
  res <- POST(.url, body = pbody, encode="json")
  res <- content(res, as = "parsed", encoding = "UTF-8")
  if(!is.null(res$errors)){
    warning(toJSON(res$errors))
  }
  res$data
}

article_query <- '{
  viewer {
    recommendation {
      feed: newest(input: {first: 30}) {
        edges {
    			node {
              id
  						title
  						slug
  						createdAt
  						state
  						public
  						live
  						summary
  						mediaHash
  						wordCount
  						dataHash
  						mediaHash
  						MAT
  						commentCount
  						responseCount
              author {
              	id
              	userName
              	displayName
              }
          	}
          }
        }
      }
    }
  }
'

newest = GQL(article_query)
newest_list = newest$viewer$recommendation$feed$edges

article = newest_list[[1]]$node
article = as.data.frame(unlist(c(article[1:14],article$author$id,
                                 article$author$userName, 
                                 article$author$displayName)))

for (i in 2:length(newest_list)) {
  print(i)
  x = newest_list[[i]]$node
  article = cbind(article, as.data.frame(unlist(c(x[1:14],x$author$id, 
                                                  x$author$userName, 
                                                  x$author$displayName))))
}

article = t(article)
row.names(article) = NULL
article = as.data.frame(article)

colnames(article) = c('id', 'title', 'slug', 'createdAt', 'state',
                      'public', 'live', 'summary', 'mediaHash', 
                      'wordCount', 'dataHash', 'MAT', 'commentCount',
                      'responseCount', 'author_id', 'author_userName',
                      'author_displayName')

article$createdAt = strptime(article$createdAt, "%Y-%m-%dT%H:%M:%OS", tz = "Asia/Shanghai")
NewestFeed <- read_csv("csv/NewestFeed.csv")
NewestFeed <- unique(rbind(NewestFeed,article))
NewestFeed = NewestFeed[!duplicated(NewestFeed$dataHash), ]
write_csv(NewestFeed, "csv/NewestFeed.csv")
