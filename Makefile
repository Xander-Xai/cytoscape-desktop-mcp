.PHONY: clean test build lint lint-fix coverage install install-release updateversion build_claude_mcpb \
        check-bridge-version stage-npm-bridge publish-npm-bridge stamp-server-json publish-registry help
.DEFAULT_GOAL := help

GRADLEW := ./gradlew

# --- MCPB bridge / MCP Registry ------------------------------------------------
# The bridge is a separate component from the app JAR, released on its own tags
# (mcpb-vX.Y.Z). claude-extension/manifest.json's `version` is the source of
# truth for the bridge and is NEVER stamped at build time — it intentionally
# diverges from the JAR version.
NPM_PKG         := @cytoscape/cytoscape-desktop-mcp-bridge
SERVER_NAME     := io.github.cytoscape/cytoscape-desktop-mcp-bridge
BRIDGE_MANIFEST := claude-extension/manifest.json
BRIDGE_PREFIX   := mcpb-v
MCPB            := build/cytoscape-mcp.mcpb
SERVER_JSON     := registry/server.json
STAMPED         := build/server.json
PUBLISHER       := .tools/mcp-publisher
REPO_URL        := https://github.com/cytoscape/cytoscape-desktop-mcp
REGISTRY        := https://registry.modelcontextprotocol.io

# Set by GitHub Actions on a `release` event. Overridable for local dry runs.
TAG             ?= $(GITHUB_REF_NAME)

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  clean            run gradle clean"
	@echo "  test             run tests with gradle test"
	@echo "  build            build the OSGi bundle JAR"
	@echo "  lint             check code formatting with Spotless"
	@echo "  lint-fix         auto-fix Spotless formatting"
	@echo "  coverage         run tests and generate JaCoCo report (build/reports/jacoco/test/html/index.html)"
	@echo "  install          install to local Maven repository"
	@echo "  install-release  build release JAR with VERSION (e.g. make install-release VERSION=1.2.3)"
	@echo "  updateversion    update project version in build.gradle"
	@echo "  build_claude_mcpb  package claude-extension/ into build/cytoscape-mcp.mcpb"
	@echo ""
	@echo "MCPB bridge / MCP Registry (bridge version comes from $(BRIDGE_MANIFEST)):"
	@echo "  check-bridge-version  assert TAG ($(BRIDGE_PREFIX)X.Y.Z) matches the bridge manifest version"
	@echo "  stage-npm-bridge      stage the npm package in build/npm-staging (no publish)"
	@echo "  stamp-server-json     write build/server.json from $(SERVER_JSON) (no publish)"
	@echo "  publish-npm-bridge    publish $(NPM_PKG) to npm if that version is absent"
	@echo "  publish-registry      publish to the MCP Registry if that version is absent"

clean:
	$(GRADLEW) clean

test:
	$(GRADLEW) test

lint:
	$(GRADLEW) spotlessCheck

lint-fix:
	$(GRADLEW) spotlessApply

coverage:
	$(GRADLEW) jacocoTestReport

build: clean
	$(GRADLEW) jar

install: clean
	$(GRADLEW) publishToMavenLocal

install-release:
	@if [ -z "$(VERSION)" ]; then echo "Error: VERSION is required. Usage: make install-release VERSION=1.2.3"; exit 1; fi
	$(GRADLEW) clean jar -PreleaseVersion=$(VERSION)

updateversion:
	@echo "Edit the 'version' property in build.gradle directly."

# manifest.json is copied verbatim — the bridge version is hand-maintained there.
# The zip is made reproducible so an unchanged bridge always yields the same
# sha256: mtimes normalized (zip embeds them), -X drops platform attributes, and
# the entry list is sorted (plain `zip -r` follows unstable readdir order).
build_claude_mcpb:
	rm -rf build/mcpb-staging build/cytoscape-mcp.mcpb
	mkdir -p build/mcpb-staging
	cp claude-extension/manifest.json build/mcpb-staging/manifest.json
	cp claude-extension/icon.png build/mcpb-staging/icon.png
	cp -r claude-extension/server build/mcpb-staging/server
	rm -f build/mcpb-staging/server/package.json build/mcpb-staging/server/README.md
	find build/mcpb-staging -exec touch -t 200001010000 {} +
	cd build/mcpb-staging && find . -type f | LC_ALL=C sort | zip -qX ../cytoscape-mcp.mcpb -@
	@echo "Built build/cytoscape-mcp.mcpb"

check-bridge-version:
	@command -v jq >/dev/null || { echo "Error: jq required for publishing (brew install jq)"; exit 1; }
	@if [ -z "$(TAG)" ]; then \
	  echo "Error: TAG is empty (GITHUB_REF_NAME unset). Pass TAG=$(BRIDGE_PREFIX)X.Y.Z"; exit 1; fi
	@case "$(TAG)" in $(BRIDGE_PREFIX)*) ;; \
	  *) echo "Error: '$(TAG)' is not a bridge tag (expected $(BRIDGE_PREFIX)X.Y.Z)"; exit 1;; esac
	@TAG_VER="$(TAG:$(BRIDGE_PREFIX)%=%)"; MAN_VER=$$(jq -r .version $(BRIDGE_MANIFEST)); \
	if [ "$$TAG_VER" != "$$MAN_VER" ]; then \
	  echo "Error: tag says $$TAG_VER but $(BRIDGE_MANIFEST) says $$MAN_VER"; exit 1; \
	fi; \
	echo "bridge version $$MAN_VER"

$(PUBLISHER):
	mkdir -p .tools
	curl -L "https://github.com/modelcontextprotocol/registry/releases/latest/download/mcp-publisher_$$(uname -s | tr '[:upper:]' '[:lower:]')_$$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/').tar.gz" \
	  | tar xz -C .tools mcp-publisher

# Staging and stamping are separate targets so they can be inspected without
# invoking anything that could actually publish.
stage-npm-bridge: check-bridge-version
	@BRIDGE_VER=$$(jq -r .version $(BRIDGE_MANIFEST)); \
	rm -rf build/npm-staging && mkdir -p build/npm-staging; \
	cp claude-extension/server/index.js build/npm-staging/index.js; \
	cp claude-extension/server/README.md build/npm-staging/README.md; \
	jq --arg v "$$BRIDGE_VER" '.version = $$v' claude-extension/server/package.json \
	  > build/npm-staging/package.json; \
	echo "staged $(NPM_PKG)@$$BRIDGE_VER in build/npm-staging"

publish-npm-bridge: stage-npm-bridge
	@BRIDGE_VER=$$(jq -r .version build/npm-staging/package.json); \
	if npm view "$(NPM_PKG)@$$BRIDGE_VER" version >/dev/null 2>&1; then \
	  echo "bridge $$BRIDGE_VER already on npm, skipping"; \
	else \
	  npm publish ./build/npm-staging --access public; \
	fi

stamp-server-json: check-bridge-version
	@if [ ! -f $(MCPB) ]; then \
	  echo "Error: $(MCPB) not found. Run 'make build_claude_mcpb' first"; exit 1; fi
	@BRIDGE_VER=$$(jq -r .version $(BRIDGE_MANIFEST)); \
	SHA=$$(openssl dgst -sha256 -r $(MCPB) | cut -d' ' -f1); \
	jq --arg v "$$BRIDGE_VER" \
	   --arg url "$(REPO_URL)/releases/download/$(TAG)/cytoscape-mcp.mcpb" \
	   --arg sha "$$SHA" \
	   '.version = $$v | (.packages[] | select(.registryType == "mcpb")) |= (.identifier = $$url | .fileSha256 = $$sha) | (.packages[] | select(.registryType == "npm")).version = $$v' \
	   $(SERVER_JSON) > $(STAMPED); \
	echo "stamped $(STAMPED) for $$BRIDGE_VER"

publish-registry: $(PUBLISHER) publish-npm-bridge stamp-server-json
	@BRIDGE_VER=$$(jq -r .version $(BRIDGE_MANIFEST)); \
	if curl -sf "$(REGISTRY)/v0.1/servers?search=$(SERVER_NAME)" \
	     | jq -e --arg n "$(SERVER_NAME)" --arg v "$$BRIDGE_VER" \
	         '[.servers[] | (.server // .) | select(.name == $$n and .version == $$v)] | length > 0' >/dev/null; then \
	  echo "$(SERVER_NAME) $$BRIDGE_VER already in registry, skipping publish"; \
	else \
	  if [ -n "$$ACTIONS_ID_TOKEN_REQUEST_URL" ]; then AUTH=github-oidc; else AUTH=github; fi; \
	  echo "authenticating with $$AUTH"; \
	  $(PUBLISHER) login $$AUTH && \
	  $(PUBLISHER) validate $(STAMPED) && \
	  $(PUBLISHER) publish $(STAMPED); \
	fi
