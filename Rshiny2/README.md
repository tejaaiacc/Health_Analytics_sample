

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
docker build . -t gcr.io/$PROJECTID/shinytab:0.1
gcloud auth configure-docker
docker push gcr.io/$PROJECTID/shinymap:0.1
docker push gcr.io/$PROJECTID/shinytab:0.1
# to check container
docker run --rm -p 8080:8080 -v /srv/shiny-server/:/srv/shiny-server/ -v /var/log/shiny-server/:/var/log/shiny-server/ gcr.io/$PROJECTID/shinymap:0.1
docker run --rm -p 8081:8081 gcr.io/$PROJECTID/shinytab:0.1

```

# PART B - Deployment 
1. Install helm [if applicable]
```
# Install nginx ingress controller uisng helm
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh
```
2. Create cluster
```
gcloud container clusters create r-cluster --num-nodes=2
gcloud container clusters get-credentials r-cluster
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
#helm repo add stable https://charts.helm.sh/stable
#helm repo update

# using newer ingress
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```
4. Deploy nginx Ingress Controller
```
#helm install nginx-ingress stable/nginx-ingress --set rbac.create=true
helm install ingress-nginx ingress-nginx/ingress-nginx 
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
