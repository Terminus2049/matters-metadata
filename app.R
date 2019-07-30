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
        ),
        
        tabPanel('Download',
                 downloadButton("downloadData", "Download"))
        
    )
}


# server ------------------------------------------------------------------

server <- function(input, output, session) {
  
    # NewestFeed -----------------------------------------------------------
    
    NewestFeed = reactiveFileReader(120000, session, 'csv/NewestFeed.csv', read_csv)
    
    output$table1 <- DT::renderDataTable({
        
        NewestFeed = NewestFeed()
        NewestFeed = NewestFeed[, c(1:11,15:17)]
        NewestFeed = unique(NewestFeed)
        
        NewestFeed$title = paste0('<a href="https://matters.news/@', 
                                  NewestFeed$author_userName,
                                  "/", NewestFeed$slug, "-", NewestFeed$mediaHash,
                                  '" target="_blank">',NewestFeed$title,'</a>')
        
        NewestFeed$author_displayName = paste0('<a href="https://matters.news/@',
                                               NewestFeed$author_userName, 
                                               '" target="_blank">',
                                               NewestFeed$author_displayName, '</a>')
        NewestFeed$dataHash = paste0('<a href="https://contributionls.github.io/public-gateway-checker/?cid=',
                                     NewestFeed$dataHash,
                                     '" target="_blank">ipfs</a>')
        
        NewestFeed = NewestFeed[, c(4,2,11,14,10,8)]
        
        names(NewestFeed) = c('創建時間', '標題', 'ipfs地址', '作者', '字數', '簡介')
        
        
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
