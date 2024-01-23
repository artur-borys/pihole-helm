.PHONY: build

test:
	helm plugin install --version v0.4.1 https://github.com/helm-unittest/helm-unittest.git || echo "unittest already installed"
	helm unittest chart

build: chart
	helm package chart -d build/

clean:
	rm -rf build
