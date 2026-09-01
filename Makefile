# Makefile - Centralized workflows for AWS and Terraform development

# References:
# GNU Make
# AWS CLI
# Terraform CLI

# Suppress directory entry/exit output
MAKEFLAGS += --no-print-directory

# Directory names
TF_DIR := terraform
BOOTSTRAP_DIR := bootstrap
CONFIG_DIR := config

# File paths for tfvars configs
PROJECT_CONFIG := $(CONFIG_DIR)/project.tfvars
STACK_CONFIG := $(CONFIG_DIR)/stack.tfvars

# Paths are relative to each Terraform root when using -chdir
PROJECT_VARS := ../$(PROJECT_CONFIG)
STACK_VARS := ../$(STACK_CONFIG)

# Main tfplan file variables
PLAN_FILE := tfplan
PLAN_PATH := $(TF_DIR)/$(PLAN_FILE)

# Backend tfplan file variables
BOOTSTRAP_PLAN_FILE := tfplan
BOOTSTRAP_PLAN_PATH := $(BOOTSTRAP_DIR)/$(BOOTSTRAP_PLAN_FILE)

# Terraform command per infrastructure directory
TF := terraform -chdir=$(TF_DIR)
BOOTSTRAP_TF := terraform -chdir=$(BOOTSTRAP_DIR)

# Paths to scripts
TOOLS_SCRIPT := scripts/check-tools.sh
AWS_PROFILE_SCRIPT := scripts/aws-profile.sh
AWS_LOGIN_SCRIPT := scripts/aws-login.sh
AWS_CONTEXT_SCRIPT := scripts/aws-context.sh
BACKEND_SCRIPT := scripts/terraform-backend.sh
BOOTSTRAP_DESTROY_SCRIPT := scripts/backend-destroy.sh
VERIFY_SCRIPT := scripts/verify.sh

# Retrieve aws region from project.tfvars
PROJECT_REGION := $(strip $(shell sed -n 's/^[[:space:]]*aws_region[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' $(PROJECT_CONFIG)))

# Assert failure upon undefined aws_region in project.tfvars
ifeq ($(PROJECT_REGION),)
$(error Could not read aws_region from $(PROJECT_CONFIG))
endif

# AWS region set to align with project.tfvars
AWS_REGION := $(PROJECT_REGION)

# Export AWS variables
export AWS_PROFILE
export AWS_REGION

# Flag to help avoid running preconditions multiple times unnecessarily
ORCHESTRATED ?= 0

# Commands brief
.DEFAULT_GOAL := help
.PHONY: \
	help confirm step \
	tools shell-validate fmt fmt-check validate check verify \
	profile login auth \
	local-deploy remote-deploy full-destroy \
	init plan plan-show apply destroy \
	bootstrap-plan bootstrap-plan-show bootstrap-apply bootstrap-destroy \
	backend-local backend-remote \
	output state-list state-show \
	clean deep-clean \


##@ End-to-end workflows

local-deploy: ## Configure, authenticate, deploy with local state, and verify
	@set -e; \
	export AUTO="$(AUTO)"; \
	$(MAKE) step STEP="1. VERIFY TOOLS"; \
	$(MAKE) tools; \
	$(MAKE) step STEP="2. SELECT AWS PROFILE"; \
	profile="$$( $(MAKE) profile )"; \
	export AWS_PROFILE="$$profile"; \
	$(MAKE) step STEP="3. AUTHENTICATE AWS"; \
	$(MAKE) login; \
	$(MAKE) step STEP="4. VALIDATE PROJECT"; \
	$(MAKE) check; \
	export ORCHESTRATED=1; \
	$(MAKE) step STEP="5. CONFIGURE LOCAL BACKEND"; \
	$(MAKE) backend-local; \
	$(MAKE) step STEP="6. PLAN INFRASTRUCTURE"; \
	$(MAKE) plan; \
	$(MAKE) confirm CONFIRM=APPLY; \
	$(MAKE) step STEP="7. APPLY INFRASTRUCTURE"; \
	$(MAKE) apply; \
	$(MAKE) step STEP="8. VERIFY DEPLOYMENT"; \
	$(MAKE) verify

remote-deploy: ## Configure, authenticate, deploy with remote S3 state, and verify
	@set -e; \
	export AUTO="$(AUTO)"; \
	$(MAKE) step STEP="1. VERIFY TOOLS"; \
	$(MAKE) tools; \
	$(MAKE) step STEP="2. SELECT AWS PROFILE"; \
	profile="$$( $(MAKE) profile )"; \
	export AWS_PROFILE="$$profile"; \
	$(MAKE) step STEP="3. AUTHENTICATE AWS"; \
	$(MAKE) login; \
	$(MAKE) step STEP="4. VALIDATE PROJECT"; \
	$(MAKE) check; \
	export ORCHESTRATED=1; \
	$(MAKE) step STEP="5. PLAN REMOTE BACKEND"; \
	$(MAKE) bootstrap-plan; \
	$(MAKE) confirm CONFIRM=BOOTSTRAP; \
	$(MAKE) step STEP="6. CREATE REMOTE BACKEND"; \
	$(MAKE) bootstrap-apply; \
	$(MAKE) step STEP="7. CONFIGURE REMOTE BACKEND"; \
	$(MAKE) backend-remote; \
	$(MAKE) step STEP="8. PLAN INFRASTRUCTURE"; \
	$(MAKE) plan; \
	$(MAKE) confirm CONFIRM=APPLY; \
	$(MAKE) step STEP="9. APPLY INFRASTRUCTURE"; \
	$(MAKE) apply; \
	$(MAKE) step STEP="10. VERIFY DEPLOYMENT"; \
	$(MAKE) verify

full-destroy: ## Destroy all infrastructure, state infrastructure, and local artifacts
	@set -e; \
	export AUTO="$(AUTO)"; \
	$(MAKE) step STEP="1. VERIFY TOOLS"; \
	$(MAKE) tools; \
	$(MAKE) step STEP="2. SELECT AWS PROFILE"; \
	profile="$$( $(MAKE) profile )"; \
	export AWS_PROFILE="$$profile"; \
	$(MAKE) step STEP="3. AUTHENTICATE AWS"; \
	$(MAKE) login; \
	$(MAKE) step STEP="4. DESTROY INFRASTRUCTURE"; \
	$(MAKE) destroy; \
	$(MAKE) step STEP="5. DESTROY REMOTE BACKEND"; \
	$(MAKE) bootstrap-destroy; \
	$(MAKE) step STEP="6. CLEAN LOCAL ARTIFACTS"; \
	$(MAKE) deep-clean


##@ Main workflows

login: ## Log into AWS and verify the active identity
	@$(AWS_LOGIN_SCRIPT)
	@[ "$(ORCHESTRATED)" = "1" ] || $(MAKE) auth

check: ## Run all static project checks
	@$(MAKE) shell-validate
	@$(MAKE) fmt-check
	@$(MAKE) validate

plan: ## Run checks, verify AWS identity, initialize backend, and create/save Terraform plan
	@rm -f $(PLAN_PATH)
	@[ "$(ORCHESTRATED)" = "1" ] || $(MAKE) check
	@[ "$(ORCHESTRATED)" = "1" ] || $(MAKE) auth
	@[ "$(ORCHESTRATED)" = "1" ] || $(MAKE) init
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
	@[ "$(ORCHESTRATED)" = "1" ] || $(MAKE) auth
	@[ "$(ORCHESTRATED)" = "1" ] || $(MAKE) init
	@$(TF) apply -input=false $(PLAN_FILE); \
		status=$$?; \
		rm -f $(PLAN_PATH); \
		exit $$status

verify: ## Verify the deployed application end to end
	@[ "$(ORCHESTRATED)" = "1" ] || $(MAKE) auth
	@[ "$(ORCHESTRATED)" = "1" ] || $(MAKE) init
	@$(VERIFY_SCRIPT)

destroy: ## Verify AWS identity and destroy managed infrastructure
	@rm -f $(PLAN_PATH)
	@$(MAKE) auth
	@$(MAKE) init
	@$(TF) destroy \
		-var-file=$(PROJECT_VARS) \
		-var-file=$(STACK_VARS)


##@ Backend state workflows

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
	@[ "$(ORCHESTRATED)" = "1" ] || $(MAKE) auth
	@[ "$(ORCHESTRATED)" = "1" ] || $(BOOTSTRAP_TF) init -input=false
	@$(BOOTSTRAP_TF) apply -input=false $(BOOTSTRAP_PLAN_FILE); \
		status=$$?; \
		rm -f $(BOOTSTRAP_PLAN_PATH); \
		exit $$status

bootstrap-destroy: ## Permanently destroy remote state after the main stack is empty
	@$(MAKE) auth
	@$(MAKE) init
	@$(BOOTSTRAP_DESTROY_SCRIPT)

backend-local: ## Enable local backend and migrate existing remote state when needed
	@[ "$(ORCHESTRATED)" = "1" ] || $(MAKE) auth
	@$(BACKEND_SCRIPT) local

backend-remote: ## Enable S3 remote backend and migrate existing local state when needed
	@[ "$(ORCHESTRATED)" = "1" ] || $(MAKE) auth
	@$(BACKEND_SCRIPT) remote

##@ Focused helpers

tools: ## Verify required local tools and versions
	@$(TOOLS_SCRIPT)

profile: ## Select or configure an AWS CLI profile
	@$(AWS_PROFILE_SCRIPT) AUTO=$(AUTO)

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

validate: ## Validate all Terraform configuration without backend access
	@$(TF) init -backend=false -input=false
	@$(TF) validate
	@$(BOOTSTRAP_TF) init -backend=false -input=false
	@$(BOOTSTRAP_TF) validate

init: ## Initialize the selected Terraform state backend
	@$(BACKEND_SCRIPT) init

plan-show: ## Show the saved Terraform plan
	@test -f "$(PLAN_PATH)" || { \
		echo "ERROR: No saved plan found"; \
		echo "Run 'make plan' first"; \
		exit 1; \
	}
	@$(TF) show $(PLAN_FILE)

bootstrap-plan-show: ## Show the saved remote state infrastructure plan
	@test -f "$(BOOTSTRAP_PLAN_PATH)" || { \
		echo "ERROR: No saved bootstrap plan found"; \
		echo "Run 'make bootstrap-plan' first"; \
		exit 1; \
	}
	@$(BOOTSTRAP_TF) show $(BOOTSTRAP_PLAN_FILE)

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

deep-clean: ## Remove generated files and empty local state after full teardown
	@test ! -f "$(TF_DIR)/s3-backend.tf" || { \
		echo "ERROR: Remote state is still enabled"; \
		echo "Run 'make bootstrap-destroy' first"; \
		exit 1; \
	}
	@if [ -f "$(TF_DIR)/terraform.tfstate" ]; then \
		main_state="$$(terraform -chdir=$(TF_DIR) state list 2>/dev/null)"; \
		if [ -n "$$main_state" ]; then \
			echo "ERROR: Main Terraform state still contains resources"; \
			echo "$$main_state"; \
			echo "Run 'make destroy' first"; \
			exit 1; \
		fi; \
	fi
	@if [ -f "$(BOOTSTRAP_DIR)/terraform.tfstate" ]; then \
		bootstrap_state="$$(terraform -chdir=$(BOOTSTRAP_DIR) state list 2>/dev/null)"; \
		if [ -n "$$bootstrap_state" ]; then \
			echo "ERROR: Bootstrap Terraform state still contains resources"; \
			echo "$$bootstrap_state"; \
			echo "Run 'make bootstrap-destroy' first"; \
			exit 1; \
		fi; \
	fi
	@$(MAKE) clean
	@rm -f $(TF_DIR)/terraform.tfstate
	@rm -f $(TF_DIR)/terraform.tfstate.*
	@rm -f $(TF_DIR)/.terraform.tfstate.lock.info
	@rm -f $(BOOTSTRAP_DIR)/terraform.tfstate
	@rm -f $(BOOTSTRAP_DIR)/terraform.tfstate.*
	@rm -f $(BOOTSTRAP_DIR)/.terraform.tfstate.lock.info
	@echo "Terraform working files and empty local state removed"


##@ Administrative helpers

help: ## Show available commands grouped by purpose
	@echo "AWS Terraform Engineering Challenge"
	@echo ""
	@echo "Usage:"
	@echo "  make <target>"
	@awk 'BEGIN {FS = ":.*## "} \
		/^##@/ {printf "\n%s\n", substr($$0, 5)} \
		/^[a-zA-Z0-9_-]+:.*## / {printf "  %-22s %s\n", $$1, $$2}' \
		$(MAKEFILE_LIST)

confirm: ## Assert user confirmation unless AUTO=1
	@[ "$(AUTO)" = "1" ] && exit 0; \
	printf '\nType %s to continue: ' "$(CONFIRM)"; \
	read -r confirmation; \
	if [ "$$confirmation" != "$(CONFIRM)" ]; then \
		echo "Operation cancelled"; \
		exit 1; \
	fi; \
	printf "\n"

step: ## Step headers to improve workflow readability
	@printf '\n\n%s\n' "------------------------------------------------------------"
	@awk -v text="$(STEP)" 'BEGIN { \
		width = 60; \
		padding = width - length(text) - 2; \
		left = int(padding / 2); \
		right = padding - left; \
		l = sprintf("%*s", left, ""); \
		r = sprintf("%*s", right, ""); \
		gsub(/ /, "*", l); \
		gsub(/ /, "*", r); \
		printf "%s %s %s\n", l, text, r; \
	}'
	@printf '%s\n\n' "------------------------------------------------------------"
