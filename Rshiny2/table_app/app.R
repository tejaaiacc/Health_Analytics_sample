rm(list = ls())
library(shiny)
library(DT)
library(shinydashboard)
library(tidyverse)

diabetes_data <- read_csv("/data/tmp.datastudio.a1c.csv")
diabetes_data <- diabetes_data[,which(names(diabetes_data) %in% c("age","condition_desc","target","sex","race","city","zipcode","state"))]
colnames(diabetes_data) <- c("Age","Condition","Uncontrolled Diabetes","Gender","Race","City","Zip Code","State")
diabetes_data$`Uncontrolled Diabetes` = as.logical(diabetes_data$`Uncontrolled Diabetes`)


ui <- dashboardPage(
  dashboardHeader(),
  dashboardSidebar(),
  dashboardBody(
    fluidRow(
      box(DT::dataTableOutput("table1"))
    )
  )
)

server <- function(input, output) {
  output$table1 <- DT::renderDataTable({
    datatable(diabetes_data,filter='top',rownames=FALSE)
  })  
}

shinyApp(ui, server)



