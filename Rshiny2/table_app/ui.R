library("DT")

fluidPage(
  h1("Massachusetts Diabetes Data"),
  wellPanel("Data source: SyntheticMass HL7 FHIR API"),
  fluidRow(
    column(12, DTOutput("diabetes_table"))
  )
)