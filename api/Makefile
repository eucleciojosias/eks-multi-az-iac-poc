.PHONY: help up down logs build lint fmt psql seed

help:
	@echo "Targets:"
	@echo "  up      docker compose up --build (foreground)"
	@echo "  down    stop and remove containers"
	@echo "  logs    tail api logs"
	@echo "  build   build the runtime image only"
	@echo "  lint    ruff check"
	@echo "  fmt     ruff format"
	@echo "  psql    open a psql shell against the running postgres service"
	@echo "  seed    fetch movies from OMDb into the running api (scripts/, isolated deps)"

up:
	docker compose up --build

down:
	docker compose down

logs:
	docker compose logs -f api

build:
	docker build -t movies-api .

lint:
	uv run ruff check app scripts

fmt:
	uv run ruff format app scripts

psql:
	docker compose exec postgres psql -U movies -d movies

seed:
	uv run --project scripts scripts/seed_movies.py
