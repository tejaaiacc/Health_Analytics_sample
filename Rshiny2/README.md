# Steps Using AWS

Notes:
 - docker images are deposited in docker hub (tejaaiacc)

Instructions using AWS CLI and Console
1. Ask DCCA IT to install AWS CLI on Windows Machine
  ```
  aws configure # add in information for API key 
  aws s3 ls # list all s3 uckets
  ```

2. Download [kubectl](https://dl.k8s.io/release/v1.21.0/bin/windows/amd64/kubectl.exe) 
  * place kubectl in a directory and add that directory to the powershell env
  ```
  $Env:Path += ";C:\path\to\kubectl"    # replace with directory where kubectl is located 
  ```

3. [Optional] Install [eksctl as non-admin user](https://docs.chocolatey.org/en-us/choco/setup#non-administrative-install) 
  ``` 
  # Install chocolatey
  Set-ExecutionPolicy Bypass -Scope Process -Force;
  .\ChocolateyInstallNonAdmin.ps1
  $Env:Path += ";C:\ProgramData\chocolatey\bin"  # default location of chocolatey
  # Install eksctl
  choco install -y eksctl
  ```

4. Create cluster using AWS console
  - log-in to AWS console
  - search EKS (from top-middle search bar) 
  - Put cluster name (e.g., test_cluster) in 'Create EKS Cluster'
  - Use default parameters including cluster service role, press Next
  - Change 'VPC' to my-eks-vpc-stack-VPC
  - unselect public subnets in 'Subnets'
  - Click Next
  - In Configure Logging, click Next
  - Click Create (this takes about 10 minutes; status: Active) 

5. Create node group with fargate using AWS Console
  - [optional] log-in to AWS console
  - Under EKS > clusters, click on the cluster created in step 4 (e.g., test_cluster) 
  - Under configuration tab, click 'Compute' tab
  - Click 'Add Fargate Profile'
  - add name
  - select available Pod Execution Role
  - click Next
  - Use 'default' for namespace, press Next
  - press Create
  
6. Once the nodes are available, use Powershell to deploy and expose kubernetes services
  ```
  # add in directory of kubectl to env path
  $Env:Path += ";C:\Users\user\Documents\apps;C:\ProgramData\chocolatey\bin"
  # list all clusters available
  aws eks list-clusters
  # Update kubeconfig to use created cluster
  aws eks --region us-east-1 update-kubeconfig --name test_cluster # change to appropriate cluster name
  # deploy and expose Rshiny app 
  kubectl create deployment shiny-map --image=docker.io/tejaaiacc/sample-shiny-map:0.1
  kubectl expose deployment shiny-map --type=NodePort --port 8080 --name test    
  kubectl port-forward svc/test 8080:8080
  ```
  On a Chrome browser, use localhost:8080 to render the Rshiny app

7. To avoid additional charges, delete fargate profile and cluster 

# Steps using GCP 

Open up terminal in GCP

### PART A - Containerization
1. Set variables and Clone repo
```
# initial set-up
gcloud auth list
gcloud config set project [project_name]
# set compute zone
gcloud config set compute/zone us-east1-d
# clone repository
git clone https://github.com/tejaaiacc/Health_Analytics_sample.git
cd Health_Analytics_sample/
cp -r Rshiny/data Rshiny2/
# export project id as environmental variable
PROJECTID=$(gcloud config get-value project)
```

2. Build docker images
```
cd Rshiny2/maps_app # listens on 8080
docker build . -t gcr.io/$PROJECTID/shinymap:0.1
cd ../table_app # listens on 8081
docker build . -t gcr.io/$PROJECTID/shinytab:0.1
gcloud auth configure-docker
docker push gcr.io/$PROJECTID/shinymap:0.1
docker push gcr.io/$PROJECTID/shinytab:0.1
# to check container
docker run --rm -p 8080:8080 -v /srv/shiny-server/:/srv/shiny-server/ -v /var/log/shiny-server/:/var/log/shiny-server/ gcr.io/$PROJECTID/shinymap:0.1
docker run --rm -p 8081:8081 gcr.io/$PROJECTID/shinytab:0.1

```

### PART B - Deployment 
1. Create cluster
```
gcloud container clusters create r-cluster --num-nodes=2
gcloud container clusters get-credentials r-cluster
```
2. Create deployment for images
```
kubectl create deployment shiny-map --image=gcr.io/$PROJECTID/shinymap:0.1
kubectl create deployment shiny-table --image=gcr.io/$PROJECTID/shinytab:0.1
kubectl get deployment
```
3. Expose deployment
```
kubectl expose deployment shiny-map --type=LoadBalancer --port 8080
kubectl expose deployment shiny-table --type=LoadBalancer --port 8081
kubectl get svc
```
4. Demo visualization
  * Obtain external IP from last command and use https://[EXTERNAL_IP]:8080 to go to Rshiny server landing page
  * to debug
  ```
  kubectl get pods
  kubectl exec [pod_name] --stdin --tty /bin/bash
  $ cd /var/log/shiny_server # this is set in shiny config
  ```
5. Delete cluster
```
gcloud container clusters delete r-cluster
```

### PART C - TO DO (Use Ingress and Helm/nginx)
1. Install helm [if applicable]
```
# Install nginx ingress controller uisng helm
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh
```
3. Set-up helm 
```
kubectl -n kube-system create sa tiller
# bind clusterrole
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
# initialize helm and install tiller
# helm init --service-account tiller   # needed?
# testing
helm version
helm ls
# using nginx - deprecated
helm repo add stable https://charts.helm.sh/stable
helm repo update

# using newer ingress
#helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
#helm repo update
```
4. Deploy nginx Ingress Controller
```
helm install nginx-ingress stable/nginx-ingress --set rbac.create=true
#helm install ingress-nginx ingress-nginx/ingress-nginx 
kubectl get service nginx-ingress-controller
```
5. Run images
```
kubectl create deployment shinyapp1 --image=gcr.io/$PROJECTID/shinymap:0.1 --port=8080
kubectl create deployment shinyapp2 --image=gcr.io/$PROJECTID/shinytab:0.1 --port=8081
kubectl get deployment 
kubectl get pods
```
6. Expose deployment
```
kubectl expose deployment shinyapp1 --target-port=8080  --type=NodePort  
kubectl expose deployment shinyapp2 --target-port=8081  --type=NodePort
```
7. Deploy ingress
```
kubectl apply -f r-ingress-nginx.yaml
kubectl get ingress r-ingress-nginx
```
8. Check visualization using external IP for the service/load-balancer
  * https://[External-IP]/zipmap/
  * https://[External-IP]/diabetestab/
