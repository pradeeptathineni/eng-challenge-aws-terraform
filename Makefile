# Makefile - Centralized workflows for AWS and Terraform development

# References:
# GNU Make
# AWS CLI
# Terraform CLI

MAKEFLAGS += --no-print-directory

TF_DIR := terraform
PLAN_FILE := tfplan
PLAN_PATH := $(TF_DIR)/$(PLAN_FILE)

TF := terraform -chdir=$(TF_DIR)

AWS_LOGIN_SCRIPT := scripts/aws-login.sh
AWS_CONTEXT_SCRIPT := scripts/aws-context.sh
VERIFY_SCRIPT := scripts/verify.sh

.DEFAULT_GOAL := help

.PHONY: help tools login auth shell-validate fmt fmt-check init validate check plan plan-show apply verify destroy output state-list state-show clean


##@ Workflows

login: ## Log into AWS and verify the active identity
	@$(AWS_LOGIN_SCRIPT)
	@$(MAKE) auth

check: ## Run all static project checks
	@$(MAKE) shell-validate
	@$(MAKE) fmt-check
	@$(MAKE) validate

plan: ## Run checks verify AWS identity and create a saved Terraform plan
	@rm -f $(PLAN_PATH)
	@$(MAKE) check
	@$(MAKE) auth
	@$(MAKE) init
	@$(TF) plan -input=false -out=$(PLAN_FILE)

apply: ## Verify AWS identity and apply the saved Terraform plan
	@test -f "$(PLAN_PATH)" || { \
		echo "ERROR: No saved plan found"; \
		echo "Run 'make plan' first"; \
		exit 1; \
	}
	@$(MAKE) auth
	@$(MAKE) init
	@$(TF) apply -input=false $(PLAN_FILE); \
		status=$$?; \
		rm -f $(PLAN_PATH); \
		exit $$status

verify: ## Verify the deployed application end to end
	@$(MAKE) auth
	@$(MAKE) init
	@$(VERIFY_SCRIPT)

destroy: ## Verify AWS identity and destroy managed infrastructure
	@rm -f $(PLAN_PATH)
	@$(MAKE) auth
	@$(MAKE) init
	@$(TF) destroy


##@ Helpers

help: ## Show available commands
	@echo "AWS Terraform Engineering Challenge"
	@echo ""
	@echo "Usage:"
	@echo "  make <target>"
	@awk 'BEGIN {FS = ":.*## "} \
		/^##@/ {printf "\n%s\n", substr($$0, 5)} \
		/^[a-zA-Z0-9_-]+:.*## / {printf "  %-16s %s\n", $$1, $$2}' \
		$(MAKEFILE_LIST)

tools: ## Check required local tools and show their versions
	@command -v bash >/dev/null 2>&1 || { echo "ERROR: Bash was not found"; exit 1; }
	@command -v curl >/dev/null 2>&1 || { echo "ERROR: curl was not found"; exit 1; }
	@command -v git >/dev/null 2>&1 || { echo "ERROR: Git was not found"; exit 1; }
	@command -v aws >/dev/null 2>&1 || { echo "ERROR: AWS CLI was not found"; exit 1; }
	@command -v terraform >/dev/null 2>&1 || { echo "ERROR: Terraform CLI was not found"; exit 1; }
	@echo "Bash:      $$(bash --version | head -n 1)"
	@echo "curl:      $$(curl --version | head -n 1)"
	@echo "Git:       $$(git --version)"
	@echo "AWS:       $$(aws --version 2>&1)"
	@echo "Terraform: $$(terraform version | head -n 1)"

auth: ## Verify AWS credentials and show the active identity
	@$(AWS_CONTEXT_SCRIPT)

shell-validate: ## Check Bash helper scripts for syntax errors
	@for script in scripts/*.sh; do \
		echo "Checking $$script"; \
		bash -n "$$script"; \
	done

fmt: ## Format all Terraform configuration
	@$(TF) fmt -recursive

fmt-check: ## Check Terraform formatting without changing files
	@$(TF) fmt -check -recursive

init: ## Initialize Terraform with the configured backend
	@$(TF) init -input=false

validate: ## Initialize without backend access and validate Terraform
	@$(TF) init -backend=false -input=false
	@$(TF) validate

plan-show: ## Show the saved Terraform plan
	@test -f "$(PLAN_PATH)" || { \
		echo "ERROR: No saved plan found"; \
		echo "Run 'make plan' first"; \
		exit 1; \
	}
	@$(TF) show $(PLAN_FILE)

output: ## Show Terraform outputs from the current state
	@$(TF) output

state-list: ## List resources currently tracked by Terraform state
	@$(TF) state list

state-show: ## Show one resource from Terraform state using RESOURCE=<address>
	@test -n "$(RESOURCE)" || { \
		echo "ERROR: RESOURCE is required"; \
		exit 1; \
	}
	@$(TF) state show '$(RESOURCE)'

clean: ## Remove generated Terraform working files without deleting state
	@rm -rf $(TF_DIR)/.terraform
	@rm -f $(PLAN_PATH)
	@rm -f $(TF_DIR)/crash.log $(TF_DIR)/crash.*.log
	@echo "Terraform working files removed"
