# FHIR query using GCP 

Using the [MITRE Synthea FHIR dataset](https://synthea.mitre.org/) that is publicly available in GCP BigQuery. Perform query according to healhtcare measure or use case

### Use case 1: Diabetes Hemoglobin Ac1 measure
  See https://ecqi.healthit.gov/ecqm/ep/2019/cms122v7

Create 3 tables (csv files based on the query below)
 1. synthea_diabetes_obs.csv - Observation (Hemoglobin A1c measure) for patients with diabetes
 2. pop_a1c.csv - population of diabetic patients 
 3. synthea_allpatients.csv - denominator file for all patients in the EHR

  Queries for the 3 tables:

  * synthea_diabetes_obs.csv

```
DECLARE report_start DATE;
DECLARE report_end DATE;
SET report_start = '2018-01-01';
SET report_end = '2018-12-31';
SELECT o.id AS observation_id,
  o.subject.patientId AS patient_id,
  o.context.encounterId AS encounter_id,
  o.value.quantity.value AS obs_value,
  o.value.quantity.unit AS obs_unit,
  o.code.coding[safe_offset(0)].code AS obs_code,
  o.code.text AS obs_desc,
  o.category[safe_offset(0)].coding[safe_offset(0)].code AS cat_code,
  O.issued,
  O.status,
  #partition by patient, order by issued date desc (latest on top)
  ROW_NUMBER() OVER
  ( PARTITION BY o.subject.patientID
    ORDER BY o.issued DESC
  ) AS latest
FROM `hcls-testing-data.fhir_20k_patients_analytics.Observation` o
WHERE 1=1
AND code.text LIKE '%A1c/Hemoglobin%'
AND o.status = 'final'
AND CAST(o.issued AS DATE) BETWEEN report_start AND report_end 
```

  * pop_a1c.csv

```
DECLARE report_start DATE;
DECLARE report_end DATE;
SET report_start = '2018-01-01';
SET report_end = '2018-12-31';
SELECT o.id AS observation_id,
SELECT p.id AS patient_id,
  p.birthDate,
  DATE_DIFF(report_end,CAST(p.birthDate AS DATE),year) AS age,
  c.code.coding[safe_offset(0)].code AS condition_code,
  c.code.coding[safe_offset(0)].display AS condition_desc
FROM `hcls-testing-data.fhir_20k_patients_analytics.Condition` c
JOIN `hcls-testing-data.fhir_20k_patients_analytics.Patient` p ON c.subject.patientID = p.id
WHERE 1=1
#All diabetics as defined by having condition like %Diabetes%
AND c.code.coding[safe_offset(0)].display like "%Diabetes%"
#The condition must not be newer than the report period.
AND CAST(c.onset.dateTime AS TIMESTAMP) < CAST(report_end AS TIMESTAMP)
#Age range 18 to 75
AND DATE_DIFF(report_end,CAST(p.birthDate AS DATE),year) BETWEEN 18 AND 75 
```

  * synthea_allpatients.csv
```
SELECT
us_core_birthsex.value.code	AS sex,
us_core_ethnicity.text.value.string AS ethnicity, 	
us_core_race.text.value.string	AS race,
address[safe_offset(0)].geolocation.latitude.value.decimal AS lat,	
address[safe_offset(0)].geolocation.longitude.value.decimal	AS long,
address[safe_offset(0)].city AS city,
address[safe_offset(0)].country	AS country,
address[safe_offset(0)].postalCode AS zipcode,
address[safe_offset(0)].state	AS state,
birthDate,
gender,
id,
maritalStatus.text AS marital_status
FROM `bigquery-public-data.fhir_synthea.patient`
``` 

Depending on use case, you may need to adjust query to obtain the resulting values. 

### Use Case 2: High Blood Pressure
For example, with blood pressure management:

```
DECLARE report_start DATE;
DECLARE report_end DATE;
SET report_start = '2018-01-01';
SET report_end = '2018-12-31';
SELECT o.id AS observation_id,
  o.subject.patientId AS patient_id,
  o.context.encounterId AS encounter_id,
  o.value.quantity.value AS obs_value,
  o.value.quantity.unit AS obs_unit,
  o.code.coding[safe_offset(0)].code AS obs_code,
  o.code.text AS obs_desc,
  o.category[safe_offset(0)].coding[safe_offset(0)].code AS cat_code,
  o.component[safe_offset(0)].code.text AS comp_code1,
  o.component[safe_offset(0)].value.quantity.value AS comp_val1,
  o.component[safe_offset(0)].value.quantity.unit AS comp_unit1,
    o.component[safe_offset(1)].code.text AS comp_code2,
  o.component[safe_offset(1)].value.quantity.value AS comp_val2,
  o.component[safe_offset(1)].value.quantity.unit AS comp_unit2,
  O.issued,
  o.status,
  #partition by patient, order by issued date desc (latest on top)
  ROW_NUMBER() OVER
  ( PARTITION BY o.subject.patientID
    ORDER BY o.issued DESC
  ) AS latest
FROM `bigquery-public-data.fhir_synthea.observation` o
WHERE 1=1
AND code.text LIKE '%Blood Pressure%'
AND o.status = 'final'
AND CAST(o.issued AS DATE) BETWEEN report_start AND report_end
```

Since the Diastolic and Systolic components are stored under a nested structure, there is a need to extract those components to create an observation table for observations with available blood pressure readings 

# Analyzing Diabetes dataset using Python/Pandas

- see synthea-fhir-diabetes.ipynb for data processing
  Notes: 
  1. Needed data files in data directory (zipped)
  2. Obtain API Key from Census API  
  