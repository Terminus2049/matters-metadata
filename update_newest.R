library(httr)
library(jsonlite)
library(readr)

url <- "https://server.matters.news/graphql/"

body <- list(operationName = 'NewestFeed', 
             variables = list(hasArticleDigestActionAuthor = F,
                              hasArticleDigestActionBookmark = T,
                              hasArticleDigestActionTopicScore = F),
             extensions = list(persistedQuery = list(version = 1,
                                                     sha256Hash = '08291b314126ef9011592f1b04652a6960fa01a5de68965451c7552188381774')),
             query = 'query NewestFeed($after: String, $hasArticleDigestActionAuthor: Boolean = false, $hasArticleDigestActionBookmark: Boolean = true, $hasArticleDigestActionTopicScore: Boolean = false) {\n  viewer {\n    id\n    recommendation {\n      feed: newest(input: {first: 10, after: $after}) {\n        ...FeedArticleConnection\n        __typename\n      }\n      __typename\n    }\n    __typename\n  }\n}\n\nfragment FeedArticleConnection on ArticleConnection {\n  pageInfo {\n    startCursor\n    endCursor\n    hasNextPage\n    __typename\n  }\n  edges {\n    cursor\n    node {\n      ...FeedDigestArticle\n      __typename\n    }\n    __typename\n  }\n  __typename\n}\n\nfragment FeedDigestArticle on Article {\n  id\n  title\n  slug\n  cover\n  summary\n  mediaHash\n  live\n  author {\n    id\n    userName\n    ...UserDigestMiniUser\n    __typename\n  }\n  ...DigestActionsArticle\n  ...FingerprintArticle\n  ...DropdownActionsArticle\n  __typename\n}\n\nfragment UserDigestMiniUser on User {\n  id\n  userName\n  displayName\n  ...AvatarUser\n  __typename\n}\n\nfragment AvatarUser on User {\n  avatar\n  __typename\n}\n\nfragment DigestActionsArticle on Article {\n  author {\n    ...UserDigestMiniUser @include(if: $hasArticleDigestActionAuthor)\n    __typename\n  }\n  createdAt\n  ...AppreciationArticle\n  ...ResponseCountArticle\n  ...BookmarkArticle @include(if: $hasArticleDigestActionBookmark)\n  ...TopicScoreArticle @include(if: $hasArticleDigestActionTopicScore)\n  ...StateActionsArticle\n  __typename\n}\n\nfragment AppreciationArticle on Article {\n  appreciationsReceivedTotal\n  __typename\n}\n\nfragment ResponseCountArticle on Article {\n  id\n  slug\n  mediaHash\n  responseCount\n  author {\n    userName\n    __typename\n  }\n  __typename\n}\n\nfragment BookmarkArticle on Article {\n  id\n  subscribed\n  __typename\n}\n\nfragment TopicScoreArticle on Article {\n  topicScore\n  __typename\n}\n\nfragment StateActionsArticle on Article {\n  state\n  __typename\n}\n\nfragment FingerprintArticle on Article {\n  id\n  dataHash\n  __typename\n}\n\nfragment DropdownActionsArticle on Article {\n  id\n  ...ArchiveButtonArticle\n  ...StickyButtonArticle\n  __typename\n}\n\nfragment StickyButtonArticle on Article {\n  id\n  sticky\n  author {\n    id\n    userName\n    __typename\n  }\n  __typename\n}\n\nfragment ArchiveButtonArticle on Article {\n  id\n  state\n  author {\n    id\n    userName\n    __typename\n  }\n  __typename\n}\n')

res <- POST(url, body = body, encode = "json")
res <- content(res, as = "parsed", encoding = "UTF-8")

newest_list = res$data$viewer$recommendation$feed$edges

article = newest_list[[1]]$node
article = c(article[1:3],article[5:16])
article = as.data.frame(unlist(article[1:14]))
for (i in 2:length(newest_list)) {
  print(i)
  x = newest_list[[i]]$node
  x = c(x[1:3],x[5:16])
  df = as.data.frame(unlist(x[1:14]))
  article = cbind(article, df)
}

article = t(article)
row.names(article) = NULL
article = as.data.frame(article)
article$public = NA
article$wordCount = NA
article$MAT = NA
article$commentCount = NA
article$responseCount = NA



article = article[,c(1,2,3,12,17,19,6,4,5,20,18,21,22,15,7,8,9)]


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


