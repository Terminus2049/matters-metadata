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

get_df = function(article){
  id = article$id
  title = article$title
  slug = article$slug
  cover = ifelse(is.null(article$cover), NA, article$cover)
  summary = article$summary
  mediaHash = article$mediaHash
  live = article$live
  userId = article$author$id
  userName = article$author$userName
  displayName = article$author$displayName
  avatar = ifelse(is.null(article$author$avatar), NA, article$author$avatar)
  createdAt = article$createdAt
  appreciationsReceivedTotal = article$appreciationsReceivedTotal
  responseCount = article$responseCount
  subscribed = article$subscribed
  state = article$state
  dataHash = article$dataHash
  sticky = article$sticky
  
  data.frame(id, title, slug, cover, summary, mediaHash, live, userId, 
             userName, displayName, avatar, createdAt, appreciationsReceivedTotal,
             responseCount, subscribed, state, dataHash, sticky)
}

df = get_df(newest_list[[1]]$node)
for (i in 2:10) {
  article = newest_list[[i]]$node
  df = rbind(df,get_df(article))
}

df$createdAt = strptime(df$createdAt, "%Y-%m-%dT%H:%M:%OS", tz = "Asia/Shanghai")


NewestFeed2 <- read_csv("csv/NewestFeed2.csv", 
                        col_types = cols(appreciationsReceivedTotal = col_double(), 
                                         avatar = col_character(), 
                                         cover = col_character()))

NewestFeed2 <- unique(rbind(NewestFeed2,df))
NewestFeed2 = NewestFeed2[!duplicated(NewestFeed2$dataHash), ]
write_csv(NewestFeed2, "csv/NewestFeed2.csv")


