INFRA := infra

.PHONY: init fmt validate plan apply destroy kubeconfig

init:
	terraform -chdir=$(INFRA) init

fmt:
	terraform -chdir=$(INFRA) fmt -recursive

validate:
	terraform -chdir=$(INFRA) validate

plan:
	terraform -chdir=$(INFRA) plan

apply:
	terraform -chdir=$(INFRA) apply

destroy:
	terraform -chdir=$(INFRA) destroy

# Write kubeconfig for the cluster (available after M2).
kubeconfig:
	aws eks update-kubeconfig \
		--region $$(terraform -chdir=$(INFRA) output -raw region) \
		--name $$(terraform -chdir=$(INFRA) output -raw cluster_name)
