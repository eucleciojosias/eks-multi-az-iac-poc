ENV  ?= staging
ROOT := envs/$(ENV)

INFRA         := .
TFLINT_CONFIG := $(CURDIR)/../.tflint.hcl

.PHONY: help envs init fmt fmt-check validate lint plan plan-out apply destroy output update-kubeconfig

ifeq ($(wildcard $(ROOT)/.),)
$(error ENV="$(ENV)" has no root at $(ROOT). Available: $(notdir $(wildcard envs/*)))
endif

help:
	@echo "Targets (all take ENV=<name>, default staging):"
	@echo "  init               terraform init for the selected env"
	@echo "  fmt                format every .tf file, recursive"
	@echo "  fmt-check          fail if anything is unformatted (what CI runs)"
	@echo "  validate           terraform validate for the selected env"
	@echo "  lint               tflint against the selected env root"
	@echo "  plan               preview changes"
	@echo "  plan-out           plan saved to $(ROOT)/tfplan (the artifact CI approves)"
	@echo "  apply              provision (prompts for confirmation)"
	@echo "  destroy            tear down"
	@echo "  output             show this env's outputs"
	@echo "  update-kubeconfig  point kubectl at this env's cluster"
	@echo
	@echo "Environments: $(notdir $(wildcard envs/*))"

envs:
	@echo $(notdir $(wildcard envs/*))

init:
	terraform -chdir=$(ROOT) init

fmt:
	terraform -chdir=$(INFRA) fmt -recursive

fmt-check:
	terraform -chdir=$(INFRA) fmt -check -diff -recursive

validate:
	terraform -chdir=$(ROOT) validate

lint:
	tflint --chdir=$(ROOT) --config=$(TFLINT_CONFIG) --init
	tflint --chdir=$(ROOT) --config=$(TFLINT_CONFIG)

plan:
	terraform -chdir=$(ROOT) plan

plan-out:
	terraform -chdir=$(ROOT) plan -out=tfplan -input=false

apply:
	terraform -chdir=$(ROOT) apply

destroy:
	terraform -chdir=$(ROOT) destroy

output:
	terraform -chdir=$(ROOT) output

update-kubeconfig:
	aws eks update-kubeconfig \
		--region $$(terraform -chdir=$(ROOT) output -raw region) \
		--name $$(terraform -chdir=$(ROOT) output -raw cluster_name)
