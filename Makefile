-include .env
export KUBECONFIG=/home/eriv_filho/.kube/my-cluster-kubeconfig.yaml
export

# ── Image names ────────────────────────────────────────────────────────────────
API_IMAGE      = read-tracker:latest
CRAWLER_IMAGE  = read-tracker-crawler:latest
FRONT_IMAGE    = read-tracker-front:latest

API_REMOTE     = $(REGISTRY)/$(NAMESPACE)/$(API_IMAGE)
CRAWLER_REMOTE = $(REGISTRY)/$(NAMESPACE)/$(CRAWLER_IMAGE)
FRONT_REMOTE   = $(REGISTRY)/$(NAMESPACE)/$(FRONT_IMAGE)

# ── Cluster / Helm ─────────────────────────────────────────────────────────────
KIND_CLUSTER    = my-k8s-local-lab
HELM_CHART      = ./deploy/helm/tracker
HELM_RELEASE    = tracker
HELM_NAMESPACE  = read-tracker
KUBE_CONTEXT    = kube-user@my-cluster

.PHONY: publish-all registry-login \
        build-api  load-api  push-api  \
        build-crawler load-crawler push-crawler \
        build-front load-front push-front \
        deploy-cluster helm-down \
        kind-apply down \
        tf-mongodbvm-apply tf-mongodbvm-destroy \
        tf-k8s-apply tf-k8s-destroy \
        tf-apply tf-destroy \
        use-context

# ── Publish all ────────────────────────────────────────────────────────────────
## publish-all: build and push all images to the remote registry
publish-all: push-api push-front

# ── Registry ───────────────────────────────────────────────────────────────────
## registry-login: authenticate against the container registry
registry-login:
	@echo "$(REGISTRY_PASSWORD)" | docker login $(REGISTRY) -u $(REGISTRY_USER) --password-stdin

# ── API ────────────────────────────────────────────────────────────────────────
## build-api: build the tracker API image
build-api:
	docker build -f deploy/docker/Dockerfile.api -t $(API_IMAGE) .

## load-api: load the API image into the local Kind cluster
load-api:
	kind load docker-image $(API_IMAGE) --name $(KIND_CLUSTER)

## push-api: build and push the API image to the remote registry
push-api: build-api registry-login
	docker tag $(API_IMAGE) $(API_REMOTE)
	docker push $(API_REMOTE)

# ── Crawler ────────────────────────────────────────────────────────────────────
## build-crawler: build the nightcrawler image
build-crawler:
	docker build -f deploy/docker/Dockerfile.crawler -t $(CRAWLER_IMAGE) .

## load-crawler: load the crawler image into the local Kind cluster
load-crawler:
	kind load docker-image $(CRAWLER_IMAGE) --name $(KIND_CLUSTER)

## push-crawler: build and push the crawler image to the remote registry
push-crawler: build-crawler registry-login
	docker tag $(CRAWLER_IMAGE) $(CRAWLER_REMOTE)
	docker push $(CRAWLER_REMOTE)

# ── Front ──────────────────────────────────────────────────────────────────────
## build-front: build the nginx front/proxy image
build-front:
	docker build -f deploy/docker/Dockerfile.front -t $(FRONT_IMAGE) .

## load-front: load the front image into the local Kind cluster
load-front:
	kind load docker-image $(FRONT_IMAGE) --name $(KIND_CLUSTER)

## push-front: build and push the front image to the remote registry
push-front: build-front registry-login
	docker tag $(FRONT_IMAGE) $(FRONT_REMOTE)
	docker push $(FRONT_REMOTE)

# ── Deploy ─────────────────────────────────────────────────────────────────────
## use-context: switch kubectl to the cloud cluster context
use-context:
	kubectl config use-context $(KUBE_CONTEXT)

## deploy-cluster: install / upgrade the Helm release in the cluster
deploy-cluster: use-context
	helm secrets upgrade --install $(HELM_RELEASE) $(HELM_CHART) \
		--namespace $(HELM_NAMESPACE) \
		--create-namespace \
		-f $(HELM_CHART)/values.secret.yaml

## helm-down: uninstall the Helm release from the cluster
helm-down: use-context
	helm uninstall $(HELM_RELEASE) --namespace $(HELM_NAMESPACE)

# ── Terraform ─────────────────────────────────────────────────────────────────
MONGODBVM_TERRAFORM_DIR = ./deploy/terraform/mongodbvm
K8S_TERRAFORM_DIR       = ./deploy/terraform/k8s-cluster

## tf-mongodbvm-apply: provision the MongoDB VM on MGC (requires deploy/terraform/mongodbvm/terraform.tfvars)
tf-mongodbvm-apply:
	terraform -chdir=$(MONGODBVM_TERRAFORM_DIR) init -upgrade
	terraform -chdir=$(MONGODBVM_TERRAFORM_DIR) apply
	./scripts/mongodb-vm-restore.sh

## tf-mongodbvm-destroy: tear down the MongoDB VM on MGC
tf-mongodbvm-destroy:
	./scripts/mongodb-vm-dump.sh
	terraform -chdir=$(MONGODBVM_TERRAFORM_DIR) destroy

## tf-k8s-apply: provision the MGC Kubernetes cluster stack
tf-k8s-apply:
	terraform -chdir=$(K8S_TERRAFORM_DIR) init -upgrade
	terraform -chdir=$(K8S_TERRAFORM_DIR) apply

## tf-k8s-destroy: tear down the MGC Kubernetes cluster stack
tf-k8s-destroy:
	terraform -chdir=$(K8S_TERRAFORM_DIR) destroy

## tf-apply: provision the Kubernetes cluster first, then the MongoDB VM stack
tf-apply:
# 	$(MAKE) tf-k8s-apply
	$(MAKE) tf-mongodbvm-apply

## tf-destroy: tear down the MongoDB VM stack first, then the Kubernetes cluster
tf-destroy:
	$(MAKE) tf-mongodbvm-destroy
	$(MAKE) tf-k8s-destroy

# ── Deprecated (raw kubectl manifests) ────────────────────────────────────────
# DEPRECATED: use deploy-cluster / helm-down instead
kind-apply:
	kubectl apply -f deploy/old-k8s/secrets/
	kubectl apply -f deploy/old-k8s/database/
	kubectl apply -f deploy/old-k8s/api/
	kubectl apply -f deploy/old-k8s/nginx/

# DEPRECATED: use helm-down instead
down:
	kubectl delete -f deploy/old-k8s/nginx/
	kubectl delete -f deploy/old-k8s/api/
	kubectl delete -f deploy/old-k8s/database/
	kubectl delete -f deploy/old-k8s/secrets/

# ── Tips ───────────────────────────────────────────────────────────────────────
# kubectl port-forward svc/nginx 8080:80