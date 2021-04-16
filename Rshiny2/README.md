

Steps using GCP terminal

# PART A - Containerization
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
docker build . -t gcr.io/$PROJECTID/shintab:0.1
```

# PART B - Deployment 

2. Create cluster
```
gcloud container clusters create r-cluster --num-nodes=2
gcloud container clusters get-credentials r-cluster
```

3. Install helm and set-up 
```
# Install nginx ingress controller uisng helm
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh
kubectl -n kube-system create sa tiller
# bind clusterrole
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
# initialize helm and install tiller
helm init --service-account tiller
# testing
helm version
helm ls
```
4. Deploy nginx Ingress Controller
```
helm install --name nginx-ingress stable/nginx-ingress --set rbac.create=true
kubectl get service nginx-ingress-controller
```
5. Run images
```
kubectl run shiny1 --image gcr.io/$PROJECTID/shinymap:0.1 --port=8080
kubectl run shiny2 --image=gcr.io/$PROJECTID/shinytab:0.1 --port=8081
```
6. Expose deployment
```
kubectl expose deployment shiny1 --target-port=8080  --type=NodePort
kubectl expose deployment shiny2 --target-port=8081  --type=NodePort
```
7. Deploy ingress
```
kubectl apply -f r-ingress-nginx.yaml
kubectl get ingress r-ingress-nginx
```
8. Check visualization using external IP
  * https://[External-IP]/zipmap
  * https://[External-IP]/diabetestab
