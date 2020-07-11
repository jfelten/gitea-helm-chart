# Copyright 2020 Keyporttech Inc.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

REGISTRY=registry.keyporttech.com:30243
DOCKERHUB_REGISTRY="keyporttech"
CHART=statsd
VERSION = $(shell yq r Chart.yaml 'version')
RELEASED_VERSION = $(shell helm repo add keyporttech https://keyporttech.github.io/helm-charts/ > /dev/null && helm repo update> /dev/null && helm show chart keyporttech/$(CHART) | yq - read 'version')
REGISTRY_TAG=${REGISTRY}/${CHART}:${VERSION}
CWD = $(shell pwd)
CURRENT_BRANCH = ${GIT-REF}

lint:
	@echo "linting..."
	helm lint
	helm template test ./
	ct lint --validate-maintainers=false --charts .
	echo "NEW CHART VERISION=$(VERSION)"
	echo "CURRENT RELEASED CHART VERSION=$(RELEASED_VERSION)"

ifeq ($(VERSION),$(RELEASED_VERSION))
	echo "$(VERSION) must be > $(RELEASED_VERSION). Please bump chart version."
	exit 1
endif

.PHONY: lint

test:
	@echo "testing..."
	ct install --charts .
	@echo "OK"
.PHONY: test

build: lint test

.PHONY: build

publish-local-registry:
	REGISTRY_TAG=${REGISTRY}/${CHART}:${VERSION}
	@echo "publishing to ${REGISTRY_TAG}"
	HELM_EXPERIMENTAL_OCI=1 helm chart save ./ ${REGISTRY_TAG}
	# helm chart export  ${REGISTRY_TAG}
	HELM_EXPERIMENTAL_OCI=1 helm chart push ${REGISTRY_TAG}
	@echo "OK"
.PHONY: publish-local-registry

publish-public-repository:
	#docker run -e GITHUB_TOKEN=${GITHUB_TOKEN} -v `pwd`:/charts/$(CHART) registry.keyporttech.com:30243/chart-testing:0.1.4 bash -cx " \
	#	echo $GITHUB_TOKEN; \
	rm -f *.tgz
	helm package .;
	curl -o releaseChart.sh https://raw.githubusercontent.com/keyporttech/helm-charts/master/scripts/releaseChart.sh; \
	chmod +x releaseChart.sh; \
	./releaseChart.sh $(CHART) $(VERSION) .;
.PHONY: publish-public-repository

deploy: publish-local-registry publish-public-repository
	rm -rf /tmp/helm-$(CHART)
	rm -rf helm-charts
	git clone git@github.com:keyporttech/helm-$(CHART).git /tmp/helm-$(CHART)
	cd /tmp/helm-$(CHART) && git remote add downstream ssh://git@git.keyporttech.com:30222/keyporttech/helm-$(CHART).git
	cd /tmp/helm-$(CHART) && git config --global user.email "bot@keyporttech.com"
	cd /tmp/helm-$(CHART) && git config --global user.name "keyporttech-bot"
	cd /tmp/helm-$(CHART) && git fetch downstream master
	cd /tmp/helm-$(CHART) && git fetch origin
	cd /tmp/helm-$(CHART) && git push -u origin downstream/master:master --force-with-lease
.PHONY:deploy
