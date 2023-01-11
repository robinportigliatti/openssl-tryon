SHELL:=/bin/bash
.PHONY: help
help: ## Display callable targets.
	@echo "Reference card for usual actions."
	@echo "Here are available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help

.PHONY: cert-openssl ## Create certificates with openssl.
cert-openssl: ## Create certificates with openssl.
	rm -rf ./ca
	rm -rf ./*.pem
	bash ./create_the_root_pair.bash
	bash ./create_the_intermediate_pair.bash
	bash ./sign_server_and_client_certificates.bash etcd1 192.168.60.21 192.168.60.1
	cp ./ca/ca-etcd/certs/*.pem .
	cp ./ca/ca-etcd/private/*.pem .
	mv ./ca-etcd-chain-cert.pem ./ca.pem
	rm -rf ./ca