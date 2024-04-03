#!/bin/sh

sub=$1

# deploy infra
az_login (){
    az login 
    az account set --subscription "$sub"
}

deploy_infra () {
    az 
}

# pull down aks creds
# install addons
addon_install() {
    # install nginx ingress controller 
    helm upgrade --install ingress-nginx ingress-nginx --repo https://kubernetes.github.io/ingress-nginx --namespace ingress-nginx --create-namespace
    #VPA
    helm install vpa fairwinds-stable/vpa --namespace vpa --create-namespace --set admissionController.enabled=false --set recommender.enabled=true --set updater.enabled=false
    helm install goldilocks --namespace vpa fairwinds-stable/goldilocks
    # 
    # install keda
     helm install keda kedacore/keda --create-namespace --namespace keda
}

az_login
deploy_infra
addon_install