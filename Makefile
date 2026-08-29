# Makefile - Centralized workflows for AWS and Terraform development

# References:
# GNU Make
# AWS CLI
# Terraform CLI

MAKEFLAGS += --no-print-directory

CONFIG_DIR := config
TF_DIR := terraform
BOOTSTRAP_DIR := bootstrap

PROJECT_CONFIG := $(CONFIG_DIR)/project.tfvars
STACK_CONFIG := $(CONFIG_DIR)/stack.tfvars

# Paths are relative to each Terraform root when using -chdir
PROJECT_VARS := ../$(PROJECT_CONFIG)
STACK_VARS := ../$(STACK_CONFIG)

PLAN_FILE := tfplan
PLAN_PATH := $(TF_DIR)/$(PLAN_FILE)

BOOTSTRAP_PLAN_FILE := tfplan
BOOTSTRAP_PLAN_PATH := $(BOOTSTRAP_DIR)/$(BOOTSTRAP_PLAN_FILE)

TF := terraform -chdir=$(TF_DIR)
BOOTSTRAP_TF := terraform -chdir=$(BOOTSTRAP_DIR)

AWS_LOGIN_SCRIPT := scripts/aws-login.sh
AWS_CONTEXT_SCRIPT := scripts/aws-context.sh
VERIFY_SCRIPT := scripts/verify.sh
BACKEND_SCRIPT := scripts/terraform-backend.sh

.DEFAULT_GOAL := help

.PHONY: help tools login auth shell-validate fmt fmt-check init validate check plan plan-show apply verify destroy bootstrap-plan bootstrap-apply bootstrap-destroy state-local state-remote output state-list state-show clean


##@ Main Workflows

login: ## Log into AWS and verify the active identity
	@$(AWS_LOGIN_SCRIPT)
	@$(MAKE) auth

check: ## Run all static project checks
	@$(MAKE) shell-validate
	@$(MAKE) fmt-check
	@$(MAKE) validate

plan: ## Run checks, verify AWS identity, initialize the selected backend, and create a saved Terraform plan
	@rm -f $(PLAN_PATH)
	@$(MAKE) check
	@$(MAKE) auth
	@$(MAKE) init
	@$(TF) plan \
		-input=false \
		-var-file=$(PROJECT_VARS) \
		-var-file=$(STACK_VARS) \
		-out=$(PLAN_FILE)

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

verify: ## Verify the deployed application end-to-end
	@$(MAKE) auth
	@$(MAKE) init
	@$(VERIFY_SCRIPT)

destroy: ## Verify AWS identity and destroy managed infrastructure
	@rm -f $(PLAN_PATH)
	@$(MAKE) auth
	@$(MAKE) init
	@$(TF) destroy \
		-var-file=$(PROJECT_VARS) \
		-var-file=$(STACK_VARS)


##@ State Workflows

bootstrap-plan: ## Create a saved plan for the remote state infrastructure
	@rm -f $(BOOTSTRAP_PLAN_PATH)
	@$(MAKE) check
	@$(MAKE) auth
	@$(BOOTSTRAP_TF) init -input=false
	@$(BOOTSTRAP_TF) plan \
		-input=false \
		-var-file=$(PROJECT_VARS) \
		-out=$(BOOTSTRAP_PLAN_FILE)

bootstrap-apply: ## Apply the saved remote state infrastructure plan
	@test -f "$(BOOTSTRAP_PLAN_PATH)" || { \
		echo "ERROR: No saved bootstrap plan found"; \
		echo "Run 'make bootstrap-plan' first"; \
		exit 1; \
	}
	@$(MAKE) auth
	@$(BOOTSTRAP_TF) init -input=false
	@$(BOOTSTRAP_TF) apply -input=false $(BOOTSTRAP_PLAN_FILE); \
		status=$$?; \
		rm -f $(BOOTSTRAP_PLAN_PATH); \
		exit $$status

bootstrap-destroy: ## Just asserts manual destruction for S3 backend bucket
	@echo
	@echo "S3 backend is protected against programmatic destroy."
	@echo "Manual destruction through console is the only option."
	@echo

state-local: ## Enable local state and migrate existing remote state when needed
	@$(MAKE) auth
	@$(BACKEND_SCRIPT) local

state-remote: ## Enable S3 remote state and migrate existing state when needed
	@$(MAKE) auth
	@$(BACKEND_SCRIPT) remote



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
	@terraform fmt -recursive $(CONFIG_DIR)
	@terraform fmt -recursive $(TF_DIR)
	@terraform fmt -recursive $(BOOTSTRAP_DIR)

fmt-check: ## Check Terraform formatting without changing files
	@terraform fmt -check -recursive $(CONFIG_DIR)
	@terraform fmt -check -recursive $(TF_DIR)
	@terraform fmt -check -recursive $(BOOTSTRAP_DIR)

init: ## Initialize the selected Terraform state backend
	@$(BACKEND_SCRIPT) init

validate: ## Validate all Terraform configuration without backend access
	@$(TF) init -backend=false -input=false
	@$(TF) validate
	@$(BOOTSTRAP_TF) init -backend=false -input=false
	@$(BOOTSTRAP_TF) validate

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
	@rm -rf $(BOOTSTRAP_DIR)/.terraform
	@rm -f $(PLAN_PATH)
	@rm -f $(BOOTSTRAP_PLAN_PATH)
	@rm -f $(TF_DIR)/crash.log $(TF_DIR)/crash.*.log
	@rm -f $(BOOTSTRAP_DIR)/crash.log $(BOOTSTRAP_DIR)/crash.*.log
	@echo "Terraform working files removed"
