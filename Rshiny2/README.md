gcloud container clusters create r-cluster --num-nodes=3
gcloud container clusters get-credentials r-cluster
# Install nginx ingress controller uisng helm