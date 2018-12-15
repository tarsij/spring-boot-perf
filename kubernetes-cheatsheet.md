# minikube

!!!! USE DOCKER_FOR_MAC with KUBERNETES instead (hostPath is working in this one)

## update

minikube update-check
minikube delete

Alternative provisioner instead of k8s.io/minikube-hostpath:
  - delete default storage class:
    kubectl delete storageclass standard
    
  - creat following storage class:
    ```
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      name: standard
    provisioner: docker.io/hostpath
    reclaimPolicy: Retain
    ```
    
    instead of the original: 
    ```
    {
      "kind": "StorageClass",
      "apiVersion": "storage.k8s.io/v1",
      "metadata": {
        "name": "standard",
        "selfLink": "/apis/storage.k8s.io/v1/storageclasses/standard",
        "uid": "749a90b6-fd4e-11e8-a910-080027c8f877",
        "resourceVersion": "390",
        "creationTimestamp": "2018-12-11T14:10:04Z",
        "labels": {
          "addonmanager.kubernetes.io/mode": "Reconcile"
        },
        "annotations": {
          "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"storage.k8s.io/v1\",\"kind\":\"StorageClass\",\"metadata\":{\"annotations\":{\"storageclass.beta.kubernetes.io/is-default-class\":\"true\"},\"labels\":{\"addonmanager.kubernetes.io/mode\":\"Reconcile\"},\"name\":\"standard\",\"namespace\":\"\"},\"provisioner\":\"k8s.io/minikube-hostpath\"}\n",
          "storageclass.beta.kubernetes.io/is-default-class": "true"
        }
      },
      "provisioner": "k8s.io/minikube-hostpath",
      "reclaimPolicy": "Delete",
      "volumeBindingMode": "Immediate"
    }
    ```

Check that the kubectl client and server versions match ()
kubectl version --short=true

## run

minikube status
minikube stop
minikube start

minikube start --kubernetes-version v1.13.0

## connect to minikube vm

minikube ssh

## dashboard

minikube dashboard

## urls

minikube service <SERVICE_NAME> --url

## mount with permissions

minikube mount --uid 26 --gid 26 --9p-version=9p2000.L  ~/Projects/cdev/data:/pgdata

!!! hard links won't work (postgress cannot be used with it)

## minikube and docker

### docker builds the images in the minikube environment

eval $(minikube docker-env)

### docker builds the images on the host

eval $(docker-machine env -u)


# kubectl

kubectl config current-context

kubectl cluster-info

kubectl get nodes

kubectl exec -it --namespace <namespace> <pod> -- /bin/bash

# docker for mac:

  - install the dashboard:
    kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
  
  - find out the pod name:
    kubectl get pods --namespace=kube-system
    
  - setup portforwarding for that pod:
    kubectl port-forward —-namespace=kube-system <kubernetes-dashboard-pod> 8443:8443

# spring-boot

passing command line arguments to the app:
mvn clean install spring-boot:run -pl application -DskipTests -Drun.jvmArguments="-Dspring.profiles.active=local"
