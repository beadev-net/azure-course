ACR_NAME ?= 'acrdemoupload0225195033'
TAG ?= '1.0'
IMAGE_NAME ?= appdemoupload:${TAG}

# Build Image and Push to ACR
build:
	az acr build --registry "$(ACR_NAME).azurecr.io" -t $(IMAGE_NAME) .