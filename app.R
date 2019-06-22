library(shiny)
library(readr)


# read data ---------------------------------------------------------------

AllAuthors <- read_csv("csv/AllAuthors.csv")
AllTags <- read_csv("csv/AllTags.csv")
NewestFeed <- read_csv("csv/NewestFeed.csv")


# NewestFeed -----------------------------------------------------------

NewestFeed$url = paste0('<a href="https://matters.news/@', 
                        NewestFeed$author_userName,
                       "/", NewestFeed$slug, "-", NewestFeed$mediaHash,
                        '" target="_blank" class="btn">原文</a>')

NewestFeed$author_displayName = paste0('<a href="https://matters.news/@',
                                      NewestFeed$author_userName, 
                                      '" target="_blank" class="btn">',
                                      NewestFeed$author_displayName, '</a>')
NewestFeed$dataHash = paste0('<a href="https://d26g9c7mfuzstv.cloudfront.net/ipfs/',
                                      NewestFeed$dataHash,
                                      '" target="_blank" class="btn">ipfs</a>')

NewestFeed = NewestFeed[, c(4,18,11,2,17,12,14,13,10,8)]

names(NewestFeed) = c('创建时间', '原文地址', 'ipfs地址', '标题', 
                     '作者', 'MAT', '回应数', '评论数', '字数', '简介')


# AllAuthors -----------------------------------------------------------------

AllAuthors$displayName = paste0('<a href="https://matters.news/@',
                                      AllAuthors$userName,
                                      '" target="_blank" class="btn">',
                                      AllAuthors$displayName, '</a>')



# AllTags -----------------------------------------------------------------

AllTags$content = paste0('<a href="https://matters.news/',
                         AllTags$id,
                         '" target="_blank" class="btn">',
                         AllTags$content, '</a>')

AllTags = AllTags[, c(2,3)]


# ui ----------------------------------------------------------------------

ui <- function(input, output, session){
    
    navbarPage(
        title = 'Matters',
        tabPanel('Articles',
                 DT::dataTableOutput("table1")
        ),
        
        tabPanel('Authors',
                 DT::dataTableOutput("table2")
        ),
        
        tabPanel('Tags',
                 DT::dataTableOutput("table3")
        )
        
    )
}


# server ------------------------------------------------------------------

server <- function(input, output, session) {
    
    output$table1 <- DT::renderDataTable({
        
        DT::datatable(NewestFeed, escape = FALSE,
                      options = list(
                          order = list(1, 'desc'),
                          pageLength = 50))
    })
    
    output$table2 <- DT::renderDataTable({
        
        DT::datatable(AllAuthors, escape = FALSE,
                      options = list(pageLength = 50))
    })
    
    output$table3 <- DT::renderDataTable({
        
        DT::datatable(AllTags, escape = FALSE,
                      options = list(pageLength = 50))
    })
    
}


# Create Shiny app --------------------------------------------------------

shinyApp(ui, server)