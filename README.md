# Files needed to launch Rshiny in Kubernetes
- The files include two Rshiny apps (using dt/tables and maps) to visualize a heathcare quality outcome 
- The healthcare quality outcome is [uncontrolled diabetes](https://ecqi.healthit.gov/ecqm/ep/2019/cms122v7)  
- The dataset used is the synthetic patient and population health data [SyntheticMass](https://synthea.mitre.org/)
- Using Synthetic mass EHR, patients with diabetes (age 18-75) were used as population with patients with hemoglobin A1C > 9 as the numerator  

### Deployment in GCP
Steps using GCP terminal:
1. Clone repository and Build the app in Docker
	```
	git clone https://github.com/tejaaiacc/Health_Analytics_sample.git
	cd Health_Analytics_sample/Rshiny
	# export project id as environmental variable
	PROJECTID=$(gcloud config get-value project)
	# Build the docker image
	docker build . -t gcr.io/$PROJECTID/shinyrun:0.1
	```
2. [Optional] Push app to Image Repo 
	```
	gcloud auth configure-docker
	docker push gcr.io/$PROJECTID/shinyrun
	```
3. Create cluster in EKS
	```
	CLUSTER_NAME = 'test_cluster'
	gcloud container clusters create $CLUSTER_NAME 
	```
4. Create deployment for image
	```
	kubectl create deployment shiny-server --image=gcr.io/$PROJECTID/shinyrun:0.1
	```
5. Expose deployment 
	```
	kubectl expose deployment shiny-server --type=LoadBalancer --port 8080
	kubectl get svc
	```
6. Demo visualization
	- Obtain external IP from last command and use https://[EXTERNAL_IP]:8080 to go to Rshiny server landing page
7. Delete cluster 
	```
	gcloud container clusters delete $CLUSTER_NAME
	```