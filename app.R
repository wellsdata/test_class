#from tutorial: https://deanattali.com/2015/06/14/mimicking-google-form-shiny/#updates


fieldsMandatory <- c("name", "favourite_pkg")

labelMandatory <- function(label) {
  tagList(
    label,
    span("*", class = "mandatory_star")
  )
}

appCSS <-
  ".mandatory_star { color: red; }"

fieldsAll <- c("name", "favourite_pkg", "used_shiny", "r_num_years", "os_type")
responsesDir <- file.path("responses")
epochTime <- function() {
  as.integer(Sys.time())
}

formData <- reactive({
  data <- sapply(fieldsAll, function(x) input[[x]])
  data <- c(data, timestamp = epochTime())
  data <- t(data)
  data
})

humanTime <- function() format(Sys.time(), "%Y%m%d-%H%M%OS")

saveData <- function(data) {
  fileName <- sprintf("%s_%s.csv",
                      humanTime(),
                      digest::digest(data))
  
  write.csv(x = data, file = file.path(responsesDir, fileName),
            row.names = FALSE, quote = TRUE)
}

# action to take when submit button is pressed
observeEvent(input$submit, {
  saveData(formData())
  shinyjs::reset("form")
  shinyjs::hide("form")
  shinyjs::show("thankyou_msg")
})

loadData <- function() {
  files <- list.files(file.path(responsesDir), full.names = TRUE)
  data <- lapply(files, read.csv, stringsAsFactors = FALSE)
  data <- do.call(rbind, data)
  data
}



shinyApp(
  ui = fluidPage(
    shinyjs::useShinyjs(),
    shinyjs::inlineCSS(appCSS),
    titlePanel("Mimicking a Google Form with a Shiny app"),
    DT::dataTableOutput("responsesTable"),
      div(
      id = "form",
            textInput("name", labelMandatory("Name"), ""),
      textInput("favourite_pkg", labelMandatory("Favourite R package")),
      checkboxInput("used_shiny", "I've built a Shiny app in R before", FALSE),
      sliderInput("r_num_years", "Number of years using R", 0, 25, 2, ticks = FALSE),
      selectInput("os_type", "Operating system used most frequently",
                  c("",  "Windows", "Mac", "Linux")),
      actionButton("submit", "Submit", class = "btn-primary"),
      shinyjs::hidden(
        div(
          id = "thankyou_msg",
          h3("Thanks, your response was submitted successfully!"),
          actionLink("submit_another", "Submit another response")
        )
      )  
    )
    
  ),
  server = function(input, output, session) {
    observe({
      mandatoryFilled <-
        vapply(fieldsMandatory,
               function(x) {
                 !is.null(input[[x]]) && input[[x]] != ""
               },
               logical(1))
      mandatoryFilled <- all(mandatoryFilled)
      
      output$responsesTable <- DT::renderDataTable(
        loadData(),
        rownames = FALSE,
        options = list(searching = FALSE, lengthChange = FALSE)
      ) 
      
      shinyjs::toggleState(id = "submit", condition = mandatoryFilled)
    })    
  }
  
)


