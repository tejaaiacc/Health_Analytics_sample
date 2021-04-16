#https://community.rstudio.com/t/r-shiny-make-a-reactive-map-of-state-by-county/63224/2
library(shiny)
library(leaflet)
library(sf)
library(magrittr)
library(tibble)
library(tidyverse)

#options(tigris_use_cache = TRUE)


# VA counties - downloaded via the awesome tigris package

ships <- read.csv("/data/tmp.datastudio.a1c.csv")
ships$zipcode <- sprintf('%05d', ships$zipcode)
# by_zip <- db_data %>% group_by(zipcode) %>% summarise(diabetes = mean(target))
# by_zip <- by_zip[!is.na(by_zip$zipcode), ]
#shape <- tigris::zctas(cb = TRUE, starts_with = c("01", "02"), class = "sf")
shape <-readRDS("/data/zipcodes.rds")
# shape <- merge(shape, by_zip, by.x = 'GEOID10', by.y = 'zipcode', all.x = TRUE, all.y = FALSE)
# data_tmp <- ships %>% group_by(zipcode) %>% summarise(diabetes = mean(target)) %>% 
		# merge(y = ., x = {shape_parent}, by.y = 'zipcode', by.x = 'GEOID10', all.x = TRUE, all.y = FALSE) 

#pal <- colorNumeric(palette = "RdYlBu",reverse=TRUE,domain = shape$diabetes)

# Define UI 
ui <- fluidPage(
  
  # Application title
  titlePanel("Massachusetts Diabetes Statistics"),
#  sidebarLayout(
#    sidebarPanel(width = 3,
     fluidRow(
       column(3,
              sliderInput("age_f","Age",min=18,max=75,value=c(18,75) )),
#                 numericInput("age_f", label = h5("Minimum age"), value = 18)),
       column(4,
              checkboxGroupInput("sex_f", "Select Gender", 
                   choices = c("F","M"), selected = c("F","M") )
                 ),
  # Top panel with county name
  verticalLayout(
    
    wellPanel(textOutput("zip")),
    
    # the map itself
    mainPanel(
      leafletOutput("map")
    )
  )
))

# Define server logic       
server <- function(input, output) {
   # Sex_Select <- reactive({ 
    # if(input$checkbox){"Coupon"}
      # else {NULL}  
  # })

  
   map_data_react <- reactive({
     
     if (is.null(input$sex_f)) {
       tmp_shape <- shape %>%
         add_column(diabetes = NA)
       return(tmp_shape)
     } else {
     
    tmp_shape<- ships %>% dplyr::filter(age >= input$age_f[1],age <= input$age_f[2]) %>% 
  	dplyr::filter(sex %in% input$sex_f) %>% 
    dplyr::group_by(zipcode) %>% dplyr::summarise(diabetes = mean(target)) %>% 
		merge(y = ., x = {shape}, by.y = 'zipcode', by.x = 'GEOID10', all.x = TRUE, all.y = FALSE) 
		# %>% filter_at(vars(diabetes),all_vars(!is.na(.)))	
	return(tmp_shape) }
	})
	
  output$map <- renderLeaflet({
	ships_data <- map_data_react()
        pal <- colorNumeric(
  palette = "RdYlBu",
  reverse=TRUE,
  domain = ships_data$diabetes)
	ships_data %>%
    leaflet() %>% 
      addProviderTiles("Stamen.Toner") %>% 
      addPolygons(stroke = FALSE,
#                  fillColor = "aliceblue",
                  fillOpacity = 0.5,
                  smoothFactor = 0.2,
                  color = ~pal(diabetes),
                  layerId = ~ZCTA5CE10) %>%
	    addLegend("bottomright", pal = pal, values = ~diabetes, title = "A1C > 9", opacity = 1)
  })
  
  # this is the fun part!
  observe({ 
    event <- input$map_shape_click
    ships_data <- map_data_react()
    output$zip <- renderText(paste(round(ships_data$diabetes[shape$GEOID10 == event$id],3), "of the population is zip code",
      ships_data$GEOID10[shape$GEOID10 == event$id], "has uncontrolled diabetes (A1C > 9)")
      )
    
  })
}

# Run the application 
shinyApp(ui = ui, server = server)


