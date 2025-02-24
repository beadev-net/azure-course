ACR_NAME ?= acrdemoupload
IMAGE_NAME ?= appdemoupload:latest

# Build Image and Push to ACR
build:
	az acr build --registry "$(ACR_NAME).azurecr.io" -t $(IMAGE_NAME) .