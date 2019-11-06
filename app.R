library(shiny)
library(readr)


# read data ---------------------------------------------------------------

AllAuthors <- read_csv("csv/AllAuthors.csv")
AllTags <- read_csv("csv/AllTags.csv")


# AllAuthors -----------------------------------------------------------------

AllAuthors$displayName = paste0('<a href="https://matters.news/@',
                                      AllAuthors$userName,
                                      '" target="_blank" class="btn">',
                                      AllAuthors$displayName, '</a>')



# AllTags -----------------------------------------------------------------

AllTags$content = paste0('<a href="https://matters.news/tags/',
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
        ),
        
        tabPanel('Download',
                 downloadButton("downloadData", "Download"))
        
    )
}


# server ------------------------------------------------------------------

server <- function(input, output, session) {
  
    # NewestFeed -----------------------------------------------------------
    
    NewestFeed = reactiveFileReader(120000, session, 'csv/NewestFeed2.csv', read_csv)
    
    output$table1 <- DT::renderDataTable({
        
        NewestFeed = NewestFeed()
        NewestFeed = NewestFeed[, c('userName', 'displayName','slug', 'mediaHash',
                                    'title', 'dataHash', 'createdAt', 'summary')]
        NewestFeed = unique(NewestFeed)
        
        NewestFeed$createdAt = NewestFeed$createdAt + 8 * 3600
        
        NewestFeed$title = paste0('<a href="https://matters.news/@', 
                                  NewestFeed$userName,
                                  "/", NewestFeed$slug, "-", NewestFeed$mediaHash,
                                  '" target="_blank">',NewestFeed$title,'</a>')
        
        NewestFeed$displayName = paste0('<a href="https://matters.news/@',
                                               NewestFeed$userName, 
                                               '" target="_blank">',
                                               NewestFeed$displayName, '</a>')
        
        NewestFeed$node = paste0('<a href="http://206.189.252.32:8080/ipfs/',
                                    NewestFeed$dataHash,
                                    '" target="_blank">ipfs</a>')
        
        NewestFeed$checker = paste0('<a href="https://contributionls.github.io/public-gateway-checker/?cid=',
                                     NewestFeed$dataHash,
                                     '" target="_blank">checker</a>')
        
        NewestFeed = NewestFeed[, c('createdAt', 'title', 'checker', 'node',
                                    'displayName', 'summary')]
        
        names(NewestFeed) = c('創建時間', '標題', 'ipfs有效地址檢測', '本站node',
                              '作者', '簡介')
        
        
        DT::datatable(NewestFeed, escape = FALSE, rownames = F,
                      options = list(
                          order = list(0, 'desc'),
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
    
    output$downloadData <- downloadHandler(
      
      filename = paste0("matters-", Sys.Date(), ".csv"),
      content = function(file) {
        write.csv(NewestFeed(), file, row.names = FALSE)
      }
    )
}


# Create Shiny app --------------------------------------------------------

shinyApp(ui, server)
