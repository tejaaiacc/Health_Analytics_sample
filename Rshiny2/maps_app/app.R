#https://community.rstudio.com/t/r-shiny-make-a-reactive-map-of-state-by-county/63224/2
library(shiny)
library(leaflet)
library(sf)
library(magrittr)
library(tibble)
library(tidyverse)

#options(tigris_use_cache = TRUE)


# Read healthcare data 
ships <- read.csv("/data/tmp.datastudio.a1c.csv")
ships$zipcode <- sprintf('%05d', ships$zipcode) # ensure zipcodes are 5-digit strings 



# MA counties - downloaded via the tigris package
#shape <- tigris::zctas(cb = TRUE, starts_with = c("01", "02"), class = "sf")
shape <-readRDS("/data/zipcodes.rds")

# Read poverty sdoh/census data 
poverty <- read.csv("/data/census_poverty.csv")
poverty$Zip.Code <- sprintf('%05d', poverty$Zip.Code)

# merge census data with zipcode polygons
shape <- merge(x={shape},y={poverty},by.x = 'GEOID10', by.y = 'Zip.Code', all.x = FALSE, all.y = TRUE)

# Define UI 
ui <- fluidPage(
  
  # Application title
  titlePanel("Massachusetts Uncontrolled Diabetes Statistics"),
     fluidRow(
       column(3,
              sliderInput("age_f","Age",min=18,max=75,value=c(18,75) )),
       column(4,
              checkboxGroupInput("sex_f", "Select Gender", 
                   choices = c("F","M"), selected = c("F","M") )
                 ),
	   column(3,
              sliderInput("poverty_f","Poverty Level",min=0.0,max=1.0,c(0.0,1.0))
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

   map_data_react <- reactive({
   
	tmp_shape <- ships %>% dplyr::filter(age >= input$age_f[1],age <= input$age_f[2]) %>% 
  	dplyr::filter(sex %in% input$sex_f) %>% 
    dplyr::group_by(zipcode) %>% summarise(diabetes = mean(target)) %>% 
		merge(y = ., x = {shape}, by.y = 'zipcode', by.x = 'GEOID10', all.x = TRUE, all.y = FALSE) %>%
    dplyr::filter(Poverty.Percentage >= input$poverty_f[1],Poverty.Percentage <= input$poverty_f[2])
	
	return(tmp_shape)
	})
	
  output$map <- renderLeaflet({
	ships_data <- map_data_react()
  
 	if (all(is.na(ships_data$diabetes))) {
	  ships_data %>%
	    leaflet() %>% 
	    addProviderTiles("Stamen.Toner") %>% 
	    addPolygons(stroke = FALSE,
	                fillColor = "aliceblue",
	                fillOpacity = 0.5,
	                smoothFactor = 0.2,
	                layerId = ~ZCTA5CE10)
	 } else {
	   pal <- colorNumeric(
	     palette = "RdYlBu",
	     na.color = "#808080",
	     reverse=TRUE,
	     domain = ships_data$diabetes
	   )
	ships_data %>%
    leaflet() %>% 
      addProviderTiles("Stamen.Toner") %>% 
      addPolygons(stroke = FALSE,
                  fillOpacity = 0.5,
                  smoothFactor = 0.2,
                  color = ~pal(diabetes),
                  layerId = ~ZCTA5CE10) %>%
	    addLegend("bottomright", pal = pal, values = ~diabetes, title = "A1C > 9", opacity = 1) }
  })
  
  # add text in bar 
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


