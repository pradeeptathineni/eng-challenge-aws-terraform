# Makefile - Centralized models for AWS/Terraform infrastructure deployment

# References:
# GNU Make
# AWS CLI
# Terraform CLI

TF_DIR := terraform
PLAN_FILE := tfplan

AWS_LOGIN_SCRIPT := scripts/aws-login.sh
AWS_CONTEXT_SCRIPT := scripts/aws-context.sh
AWS_PROFILE ?= default

.DEFAULT_GOAL := help

.PHONY: help tools version login auth shell-validate fmt fmt-check init init-ci validate validate-ci plan plan-show apply destroy output state-list state-show clean

help: ## Show available commands
	@echo "AWS Terraform Engineering Challenge"
	@echo ""
	@echo "Usage:"
	@echo "  make <target>"
	@echo ""
	@echo "Targets:"
	@awk 'BEGIN {FS = ":.*## "}; /^[a-zA-Z_-]+:.*## / {printf "  %-16s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

tools: ## Check if local tools are installed and their versions
	@command -v bash >/dev/null 2>&1 || { echo "ERROR: Bash was not found"; exit 1; }
	@command -v git >/dev/null 2>&1 || { echo "ERROR: Git was not found"; exit 1; }
	@command -v aws >/dev/null 2>&1 || { echo "ERROR: AWS CLI was not found"; exit 1; }
	@command -v terraform >/dev/null 2>&1 || { echo "ERROR: Terraform was not found"; exit 1; }
	@echo "Git:       $$(git --version)"
	@echo "AWS:       $$(aws --version 2>&1)"
	@echo "Terraform: $$(terraform version | head -n 1)"

version: ## Show the active Terraform version
	@terraform version

login: ## Log into AWS and verify the active identity
	@$(AWS_LOGIN_SCRIPT) "$(AWS_PROFILE)"

auth: ## Verify AWS credentials and show the active AWS account
	@$(AWS_CONTEXT_SCRIPT)

shell-validate: ## Check Bash helper scripts for syntax errors
	@for script in scripts/*.sh; do \
		echo "Checking $$script"; \
		bash -n "$$script"; \
	done

fmt: ## Format all Terraform configuration
	@terraform -chdir=$(TF_DIR) fmt -recursive

fmt-check: ## Check Terraform formatting without changing files
	@terraform -chdir=$(TF_DIR) fmt -check -recursive

init: ## Initialize Terraform for local development
	@terraform -chdir=$(TF_DIR) init

init-ci: ## Initialize Terraform for CI without backend access
	@terraform -chdir=$(TF_DIR) init -backend=false -input=false

validate: init ## Initialize and validate Terraform configuration
	@terraform -chdir=$(TF_DIR) validate

validate-ci: init-ci ## Initialize and validate Terraform configuration in CI
	@terraform -chdir=$(TF_DIR) validate

plan: validate ## Check AWS identity and create a saved Terraform plan
	@$(MAKE) --no-print-directory auth
	@terraform -chdir=$(TF_DIR) plan -out=$(PLAN_FILE)

plan-show: ## Show the saved Terraform plan
	@test -f "$(TF_DIR)/$(PLAN_FILE)" || { \
		echo "ERROR: No saved plan found"; \
		echo "Run 'make plan' first"; \
		exit 1; \
	}
	@terraform -chdir=$(TF_DIR) show $(PLAN_FILE)

apply: ## Check AWS identity and apply the saved Terraform plan
	@if [ ! -f "$(TF_DIR)/$(PLAN_FILE)" ]; then \
		echo "ERROR: No saved plan found"; \
		echo "Run 'make plan' first"; \
		exit 1; \
	fi
	@$(MAKE) --no-print-directory auth
	@terraform -chdir=$(TF_DIR) apply $(PLAN_FILE)

destroy: init ## Check AWS identity and destroy managed infrastructure
	@$(MAKE) --no-print-directory auth
	@terraform -chdir=$(TF_DIR) destroy

output: ## Show Terraform outputs from the current state
	@terraform -chdir=$(TF_DIR) output

state-list: ## List resources currently tracked by Terraform state
	@terraform -chdir=$(TF_DIR) state list

state-show: ## Show one resource from Terraform state using RESOURCE=<address>
	@test -n "$(RESOURCE)" || { echo "ERROR: RESOURCE is required"; exit 1; }
	@terraform -chdir=$(TF_DIR) state show '$(RESOURCE)'

clean: ## Remove generated Terraform working files without deleting state
	@rm -rf $(TF_DIR)/.terraform
	@rm -f $(TF_DIR)/$(PLAN_FILE)
	@rm -f $(TF_DIR)/crash.log $(TF_DIR)/crash.*.log
	@echo "Terraform working files removed"
