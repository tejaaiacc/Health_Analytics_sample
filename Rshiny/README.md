# Files needed to launch Rshiny in Kubernetes
- The files include two Rshiny apps (using dt/tables and maps) to visualize a heathcare quality outcome 
- The healthcare quality outcome is [uncontrolled diabetes](https://ecqi.healthit.gov/ecqm/ep/2019/cms122v7)  
- The dataset used is the synthetic patient and population health data [SyntheticMass](https://synthea.mitre.org/)
- Using Synthetic mass EHR, patients with diabetes (age 18-75) were used as population with patients with hemoglobin A1C > 9 as the numerator  

### Deployment in GCP
Enable services:
  * compute 
  * kubernetes services
  * container registry
  
Steps using GCP terminal:
1. Clone repository and Build the app in Docker
	```
	# initial set-up
	gcloud auth list
	gcloud config set project [project_name]
	# set compute zone
	gcloud config set compute/zone us-east1-d
	# clone repository
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
	docker push gcr.io/$PROJECTID/shinyrun:0.1
	```
3. Create cluster in EKS
	```
	CLUSTERNAME='testcluster'
	gcloud container clusters create $CLUSTERNAME 
	kubectl get nodes
	```
4. Create deployment for image
	```
	kubectl create deployment shiny-server --image=gcr.io/$PROJECTID/shinyrun:0.1
	kubectl get deployment
	```
5. Expose deployment 
	```
	kubectl expose deployment shiny-server --type=LoadBalancer --port 8080
	kubectl get svc
	```
6. Demo visualization
	- Obtain external IP from last command and use https://[EXTERNAL_IP]:8080 to go to Rshiny server landing page
	- to debug
	```
	kubectl get pods
	kubectl exec [pod_name] --stdin --tty /bin/bash
	$ cd /var/log/shiny_server # this is set in shiny config
	```
7. Delete cluster 
	```
	gcloud container clusters delete $CLUSTER_NAME
	```