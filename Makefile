# Terraform directory and saved plan location.
TF_DIR := terraform
PLAN_FILE := tfplan

.DEFAULT_GOAL := help

.PHONY: help version fmt fmt-check init init-noback validate validate-ci plan apply destroy output clean

help: ## Show available commands
	@echo "AWS Terraform Engineering Challenge"
	@echo ""
	@echo "Usage:"
	@echo "  make <target>"
	@echo ""
	@echo "Targets:"
	@awk 'BEGIN {FS = ":.*## "}; /^[a-zA-Z_-]+:.*## / {printf "  %-12s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

version: ## Show the active Terraform version
	@terraform version

fmt: ## Format all Terraform configuration
	@terraform -chdir=$(TF_DIR) fmt -recursive

fmt-check: ## Check Terraform formatting without modifying files
	@terraform -chdir=$(TF_DIR) fmt -check -recursive

init: ## Initialize Terraform for local dev and install required providers
	@terraform -chdir=$(TF_DIR) init

init-noback: ## Initialize Terraform without accessing backend state
	@terraform -chdir=$(TF_DIR) init -backend=false -input=false

validate: init ## Validate Terraform configuration
	@terraform -chdir=$(TF_DIR) validate

validate-ci: init-noback ## Initialize and validate Terraform configuration in CI
	@terraform -chdir=$(TF_DIR) validate

plan: validate ## Validate and create a saved Terraform execution plan
	@terraform -chdir=$(TF_DIR) plan -out=$(PLAN_FILE)

apply: ## Apply the previously generated Terraform plan
	@if [ ! -f "$(TF_DIR)/$(PLAN_FILE)" ]; then \
		echo "ERROR: No saved plan found. Run 'make plan' first."; \
		exit 1; \
	fi
	@terraform -chdir=$(TF_DIR) apply $(PLAN_FILE)

destroy: init ## Destroy infrastructure managed by the current Terraform state
	@terraform -chdir=$(TF_DIR) destroy

output: ## Display Terraform outputs from the current state
	@terraform -chdir=$(TF_DIR) output

clean: ## Remove generated Terraform working files without deleting state
	@rm -rf $(TF_DIR)/.terraform
	@rm -f $(TF_DIR)/$(PLAN_FILE)
	@rm -f $(TF_DIR)/crash.log $(TF_DIR)/crash.*.log
	@echo "Terraform working files removed."