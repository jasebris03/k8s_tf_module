# Makefile for Terraform EKS Module
# This file provides common development tasks and shortcuts

.PHONY: help install-hooks run-hooks format validate lint security-check test clean docs

# Default target
help:
	@echo "🔧 Terraform EKS Module Development Commands"
	@echo "=============================================="
	@echo ""
	@echo "📦 Setup Commands:"
	@echo "  install-hooks    Install pre-commit hooks"
	@echo "  install-tools    Install required development tools"
	@echo ""
	@echo "🔍 Quality Commands:"
	@echo "  run-hooks        Run all pre-commit hooks"
	@echo "  format           Format Terraform code"
	@echo "  validate         Validate Terraform code"
	@echo "  lint             Run Terraform linting"
	@echo "  security-check   Run security checks"
	@echo "  test             Run all quality checks"
	@echo ""
	@echo "📚 Documentation:"
	@echo "  docs             Generate documentation"
	@echo ""
	@echo "🧹 Maintenance:"
	@echo "  clean            Clean up generated files"
	@echo "  update-hooks     Update pre-commit hooks"
	@echo ""

# Install pre-commit hooks
install-hooks:
	@echo "🔧 Installing pre-commit hooks..."
	pip install pre-commit
	pre-commit install
	pre-commit install --hook-type commit-msg
	@echo "✅ Pre-commit hooks installed successfully!"

# Install development tools
install-tools:
	@echo "📦 Installing development tools..."
	# Install Terraform
	@if ! command -v terraform &> /dev/null; then \
		echo "Installing Terraform..."; \
		brew install terraform; \
	fi
	# Install tflint
	@if ! command -v tflint &> /dev/null; then \
		echo "Installing tflint..."; \
		brew install tflint; \
	fi
	# Install checkov
	@if ! command -v checkov &> /dev/null; then \
		echo "Installing checkov..."; \
		pip install checkov; \
	fi
	# Install tfsec
	@if ! command -v tfsec &> /dev/null; then \
		echo "Installing tfsec..."; \
		brew install tfsec; \
	fi
	# Install infracost
	@if ! command -v infracost &> /dev/null; then \
		echo "Installing infracost..."; \
		brew install infracost; \
	fi
	# Install terraform-docs
	@if ! command -v terraform-docs &> /dev/null; then \
		echo "Installing terraform-docs..."; \
		brew install terraform-docs; \
	fi
	@echo "✅ Development tools installed successfully!"

# Run all pre-commit hooks
run-hooks:
	@echo "🔍 Running pre-commit hooks..."
	pre-commit run --all-files
	@echo "✅ Pre-commit hooks completed!"

# Format Terraform code
format:
	@echo "🎨 Formatting Terraform code..."
	terraform fmt -recursive
	@echo "✅ Terraform code formatted!"

# Validate Terraform code
validate:
	@echo "✅ Validating Terraform code..."
	@for dir in modules/* examples/*; do \
		if [ -f "$$dir/main.tf" ]; then \
			echo "Validating $$dir..."; \
			cd "$$dir" && terraform init -backend=false && terraform validate && cd -; \
		fi \
	done
	@echo "✅ Terraform validation completed!"

# Run Terraform linting
lint:
	@echo "🔍 Running Terraform linting..."
	tflint --init
	tflint
	@echo "✅ Terraform linting completed!"

# Run security checks
security-check:
	@echo "🔒 Running security checks..."
	@if [ -f "scripts/security_check.py" ]; then \
		python scripts/security_check.py; \
	else \
		echo "Security check script not found"; \
	fi
	@echo "✅ Security checks completed!"

# Run all quality checks
test: format validate lint security-check
	@echo "🎯 All quality checks completed!"

# Generate documentation
docs:
	@echo "📚 Generating documentation..."
	terraform-docs markdown modules/eks > modules/eks/README.md
	@echo "✅ Documentation generated!"

# Clean up generated files
clean:
	@echo "🧹 Cleaning up generated files..."
	find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	find . -name "*.tfstate" -type f -delete 2>/dev/null || true
	find . -name "*.tfstate.backup" -type f -delete 2>/dev/null || true
	find . -name ".terraform.lock.hcl" -type f -delete 2>/dev/null || true
	find . -name "security-check-report.json" -type f -delete 2>/dev/null || true
	find . -name "checkov-results.json" -type f -delete 2>/dev/null || true
	find . -name "tfsec-results.json" -type f -delete 2>/dev/null || true
	@echo "✅ Cleanup completed!"

# Update pre-commit hooks
update-hooks:
	@echo "🔄 Updating pre-commit hooks..."
	pre-commit autoupdate
	@echo "✅ Pre-commit hooks updated!"

# Run cost estimation
cost:
	@echo "💰 Running cost estimation..."
	@for dir in examples/*; do \
		if [ -d "$$dir" ]; then \
			echo "Estimating costs for $$dir..."; \
			cd "$$dir" && infracost breakdown --path . --format json --out-file infracost-report.json && cd -; \
		fi \
	done
	@echo "✅ Cost estimation completed!"

# Run compliance checks
compliance:
	@echo "📋 Running compliance checks..."
	terraform-compliance -f .terraform-compliance -p modules/eks
	@echo "✅ Compliance checks completed!"

# Setup development environment
setup: install-tools install-hooks
	@echo "🚀 Development environment setup completed!"

# Run full CI pipeline
ci: test docs compliance cost
	@echo "🎯 Full CI pipeline completed!"

# Show current status
status:
	@echo "📊 Current Status:"
	@echo "=================="
	@echo "Terraform version: $(shell terraform version 2>/dev/null | head -n1 || echo 'Not installed')"
	@echo "tflint version: $(shell tflint --version 2>/dev/null || echo 'Not installed')"
	@echo "checkov version: $(shell checkov --version 2>/dev/null || echo 'Not installed')"
	@echo "tfsec version: $(shell tfsec --version 2>/dev/null || echo 'Not installed')"
	@echo "infracost version: $(shell infracost --version 2>/dev/null || echo 'Not installed')"
	@echo "terraform-docs version: $(shell terraform-docs version 2>/dev/null || echo 'Not installed')"
	@echo "pre-commit version: $(shell pre-commit --version 2>/dev/null || echo 'Not installed')" 