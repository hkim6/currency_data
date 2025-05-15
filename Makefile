# Package Management
install_poetry:
	@poetry --version || pip install poetry

deps:
	@echo "Installing dependencies"
	poetry lock
	poetry install

freeze:
	@echo "Freezing dependencies"
	poetry export -f requirements.txt --output requirements.txt --without-hashes

# Infrastructure

deploy_infra:
	@echo "Applying changes to Infrastructure"
	cd infrastructure && yes | terraform apply

# Linting and Formatting

format:
	@echo "Formatting code"
	poetry run ruff format de_exercise_prt

check:
	ruff check de_exercise_prt
	mypy de_exercise_prt --ignore-missing-imports --disallow-untyped-defs

set_env:
	./scripts/set_env_var.sh
	@echo "Environment variables set"

# Create Tables
create_tables:
	@echo "Creating tables"
	poetry run python ./de_exercise_prt/sql_utils.py run-query-from-file ./queries/schema.sql

run_query:
	@echo "Running queries"
	poetry run python ./de_exercise_prt/sql_utils.py run-query-from-file $(FILE) --show-output

# Load Data

load_symbols:
	@echo "Loading symbols"
	poetry run python ./de_exercise_prt/currency_ingestion.py ingest_symbols

load_data:
	@echo "Loading data"
	poetry run python ./de_exercise_prt/currency_ingestion.py ingest_csv ./data/daily_forex_rates.csv

build_image:
	@echo "Building Docker image"
	docker build --platform linux/arm64 -t de-exercise-image .
	docker tag de-exercise-image:latest ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/hk-repo

push_image:
	aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/hk-repo
	docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/hk-repo