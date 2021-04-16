library("DT")
library("tidyverse")

diabetes_data <- read_csv("/data/tmp.datastudio.a1c.csv")
diabetes_data <- diabetes_data[,which(names(diabetes_data) %in% c("age","condition_desc","target","sex","race","city","zipcode","state"))]
colnames(diabetes_data) <- c("Age","Condition","Uncontrolled Diabetes","Gender","Race","City","Zip Code","State")
diabetes_data$`Uncontrolled Diabetes` = as.logical(diabetes_data$`Uncontrolled Diabetes`)

function(input, output, session) {
  
  output$diabetes_table <- renderDT({
    diabetes_data %>%
      datatable(filter = 'top', rownames=FALSE
                )
  })
}