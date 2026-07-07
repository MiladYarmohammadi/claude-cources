# Local development helpers — mirrors what CI runs.
CHART := charts/app
ENV_VALUES := $(wildcard gitops/apps/*/envs/*/values.yaml)

.PHONY: help lint template validate package clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-12s %s\n", $$1, $$2}'

lint: ## helm lint + yamllint
	helm lint --strict $(CHART)
	@command -v yamllint >/dev/null && yamllint . || echo "yamllint not installed — skipping"

template: ## Render the chart with defaults and every gitops env values file
	helm template smoke $(CHART) > /dev/null && echo "defaults: OK"
	@for v in $(ENV_VALUES); do \
		helm template smoke $(CHART) -f $$v > /dev/null && echo "$$v: OK" || exit 1; \
	done

validate: template ## Render + kubeconform schema validation
	@command -v kubeconform >/dev/null || { echo "kubeconform not installed"; exit 1; }
	helm template smoke $(CHART) | kubeconform -strict -summary -ignore-missing-schemas

package: ## Package the chart into .packaged/
	mkdir -p .packaged
	helm package $(CHART) --destination .packaged

clean:
	rm -rf .packaged
