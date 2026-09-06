# docker-strapi — Strapi v5 images for Alpine and Debian-slim.
#
# release-versions/ drives everything: a push to any file in it triggers
# publish-docker-images.yml, which builds both variants, smoke-tests amd64,
# pushes to Docker Hub and cuts a GitHub release.

SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

VARIANTS := alpine debian
# `make build VARIANT=alpine` narrows any per-variant target to one variant.
VARIANT ?=
TARGETS := $(if $(VARIANT),$(VARIANT),$(VARIANTS))

STRAPI_VERSION := $(shell tr -d '[:space:]' < release-versions/strapi-latest.txt)
NODE_VERSION ?= 24
VCS_REF := $(shell git rev-parse HEAD)
TAG_PREFIX := strapi

.PHONY: help
help: ## Show this help
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'
	@echo
	@echo "  Per-variant targets take VARIANT=alpine|debian"
	@echo "  Building Strapi $(STRAPI_VERSION) on node $(NODE_VERSION)"

.PHONY: tools
tools: ## Install the pinned toolchain from mise.toml
	@command -v mise >/dev/null || { echo "mise not on PATH — see https://mise.jdx.dev or .devcontainer" >&2; exit 1; }
	mise install

.PHONY: hooks
hooks: ## Install the git pre-commit hook
	pre-commit install

.PHONY: lint
lint: ## Run every pre-commit hook over the whole tree
	pre-commit run --all-files

.PHONY: fmt
fmt: ## Reformat YAML and shell in place
	pre-commit run yamlfmt --all-files || true
	pre-commit run shfmt-src --all-files || true

.PHONY: versions
versions: ## Show what release-versions/ currently pins
	@printf 'strapi        %s\n' "$(STRAPI_VERSION)"
	@printf 'node          %s\n' "$(NODE_VERSION)"
	@printf 'node:alpine   %s\n' "$$(cat release-versions/node-alpine-digest.txt)"
	@printf 'node:debian   %s\n' "$$(cat release-versions/node-debian-digest.txt)"

.PHONY: build
build: ## Build the image(s) locally
	@for v in $(TARGETS); do \
		echo "==> build $$v (strapi $(STRAPI_VERSION))"; \
		docker build \
			--build-arg STRAPI_VERSION=$(STRAPI_VERSION) \
			--build-arg NODE_VERSION=$(NODE_VERSION) \
			--build-arg VCS_REF=$(VCS_REF) \
			-t $(TAG_PREFIX)-$$v-test \
			images/strapi-$$v; \
	done

.PHONY: smoke
smoke: ## Boot the built image(s) and wait for a clean start
	@for v in $(TARGETS); do \
		echo "==> smoke $$v"; \
		./smoke-test.sh $(TAG_PREFIX)-$$v-test; \
	done

.PHONY: scan
scan: ## CVE scan the built image(s) — advisory, same as CI
	@command -v trivy >/dev/null || { echo "trivy not on PATH — see .devcontainer" >&2; exit 1; }
	@for v in $(TARGETS); do \
		echo "==> scan $$v"; \
		trivy image --scanners vuln --ignore-unfixed \
			--severity CRITICAL,HIGH $(TAG_PREFIX)-$$v-test; \
	done

.PHONY: check
check: lint build smoke ## Everything CI runs: lint, build both variants, smoke both

.PHONY: shell
shell: ## Open a shell in a built image
	@test -n "$(VARIANT)" || { echo "error: VARIANT is not set — e.g. make shell VARIANT=alpine" >&2; exit 1; }
	docker run --rm -it --entrypoint sh $(TAG_PREFIX)-$(VARIANT)-test

.PHONY: example-up
example-up: ## Run an example stack, e.g. make example-up EXAMPLE=strapi-postgres
	@test -n "$(EXAMPLE)" || { echo "error: EXAMPLE is not set — one of: $$(ls examples)" >&2; exit 1; }
	docker compose -f examples/$(EXAMPLE)/docker-compose.yml up

.PHONY: example-down
example-down: ## Tear an example stack down, volumes included
	@test -n "$(EXAMPLE)" || { echo "error: EXAMPLE is not set — one of: $$(ls examples)" >&2; exit 1; }
	docker compose -f examples/$(EXAMPLE)/docker-compose.yml down -v

.PHONY: clean
clean: ## Remove the locally built test images
	-docker rmi $(addprefix $(TAG_PREFIX)-,$(addsuffix -test,$(VARIANTS))) 2>/dev/null

.PHONY: update-hooks
update-hooks: ## Bump pinned hook revisions
	pre-commit autoupdate
