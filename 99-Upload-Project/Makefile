ACR_NAME ?= acrdemouploadxxx
IMAGE_NAME ?= appdemoupload:1.0

# Build Image and Push to ACR
build:
	az acr build --registry "$(ACR_NAME).azurecr.io" -t $(IMAGE_NAME) .