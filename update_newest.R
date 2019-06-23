library(httr)
library(jsonlite)
library(readr)

url <- "https://server.matters.news/"
GQL <- function(query, .url = url){
  pbody <- list(query = query)
  res <- POST(.url, body = pbody, encode="json")
  res <- content(res, as = "parsed", encoding = "UTF-8")
  if(!is.null(res$errors)){
    warning(toJSON(res$errors))
  }
  res$data
}

article_query <- 'query NewestFeed($cursor: String, 
$hasArticleDigestActionAuthor: Boolean = false, 
$hasArticleDigestActionBookmark: Boolean = false, 
$hasArticleDigestActionTopicScore: Boolean = false) {
  viewer {
    id
    recommendation {
      feed: newest(input: {first: 10, after: $cursor}) {
        ...FeedArticleConnection
        __typename
      }
      __typename
    }
    __typename
  }
}

fragment FeedArticleConnection on ArticleConnection {
  pageInfo {
    startCursor
    endCursor
    hasNextPage
    __typename
  }
  edges {
    cursor
    node {
      ...FeedDigestArticle
    }
  }
}

fragment FeedDigestArticle on Article {
  id
  title
  slug
  summary
  mediaHash
  live
  public
  wordCount
  commentCount
  author {
    id
    userName
    ...UserDigestMiniUser
  }
  ...DigestActionsArticle
  ...FingerprintArticle
}

fragment UserDigestMiniUser on User {
  id
  userName
  displayName
}

fragment DigestActionsArticle on Article {
  author {
    ...UserDigestMiniUser @include(if: $hasArticleDigestActionAuthor)
  }
  createdAt
  ...MATArticle
  ...ResponseCountArticle
  ...BookmarkArticle @include(if: $hasArticleDigestActionBookmark)
  ...TopicScoreArticle @include(if: $hasArticleDigestActionTopicScore)
  ...StateActionsArticle
}

fragment MATArticle on Article {
  MAT
}

fragment ResponseCountArticle on Article {
  id
  slug
  mediaHash
  responseCount
  author {
    userName
  }
}

fragment BookmarkArticle on Article {
  id
  subscribed
}

fragment TopicScoreArticle on Article {
  topicScore
}

fragment StateActionsArticle on Article {
  state
}

fragment FingerprintArticle on Article {
  id
  dataHash
}
'

newest = GQL(article_query)
newest_list = newest$viewer$recommendation$feed$edges

article = newest_list[[1]]$node
article = as.data.frame(unlist(c(article[1:9],article$author$id,
                                 article$author$userName, 
                                 article$author$displayName,
                                 article[11:15])))

for (i in 2:length(newest_list)) {
  print(i)
  x = newest_list[[i]]$node
  article = cbind(article, as.data.frame(unlist(c(x[1:9],x$author$id,
                                                  x$author$userName, 
                                                  x$author$displayName,
                                                  x[11:15]))))
}

article = t(article)
row.names(article) = NULL
article = as.data.frame(article)

colnames(article) = c('id', 'title', 'slug', 'summary', 'mediaHash',
                      'live', 'public', 'wordCount', 'commentCount','author_id', 
                      'author_userName', 'author_displayName', 'createdAt', 'MAT',
                      'responseCount', 'state', 'dataHash')
article = article[, c("id", 'title', 'slug', 'createdAt', 'state',
                       'public', 'live', 'summary', 'mediaHash', 'wordCount',
                       'dataHash', 'MAT', 'commentCount', 'responseCount',
                       'author_id', 'author_userName', 'author_displayName')]

NewestFeed <- read_csv("csv/NewestFeed.csv")
NewestFeed <- unique(rbind(NewestFeed,article))
write_csv(NewestFeed, "csv/NewestFeed.csv")
