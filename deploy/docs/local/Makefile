.DEFAULT_GOAL := help
.RECIPEPREFIX := >

ROOT_DIR := ../../..
HOST ?= 127.0.0.1
PORT ?= 8000
DOCKER_COMPOSE ?= docker compose

export HOST
export PORT

.PHONY: help build up down logs

help:
>@echo "Available targets:"
>@echo "  make build  Build the local docs Docker image"
>@echo "  make up     Start docs locally on http://$(HOST):$(PORT)"
>@echo "  make down   Stop the local docs container"
>@echo "  make logs   View container logs"

build:
>$(DOCKER_COMPOSE) -f compose.yml build

up:
>$(DOCKER_COMPOSE) -f compose.yml up --build -d
>@echo "Documentation available at http://$(HOST):$(PORT)"

down:
>$(DOCKER_COMPOSE) -f compose.yml down

logs:
>$(DOCKER_COMPOSE) -f compose.yml logs -f