.PHONY: help venv install setup run dev worker tailwind test migrate makemigrations shell superuser collectstatic lint format clean reset

VENV := .venv
PYTHON := $(VENV)/bin/python
PIP := $(VENV)/bin/pip

HOST := 0.0.0.0
PORT := 8085

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

venv: ## Create .venv if it does not exist
	test -d $(VENV) || python3 -m venv $(VENV)

install: venv ## Install all Python and Node dependencies
	$(PIP) install -r requirements.txt
	npm install

setup: install migrate collectstatic ## Bootstrap project from scratch (install deps, run migrations, collect static)

run: venv ## Start Daphne, Celery worker, and Tailwind in parallel
	$(MAKE) -j3 dev worker tailwind

dev: venv ## Start Daphne ASGI server
	$(VENV)/bin/daphne -b $(HOST) -p $(PORT) config.asgi:application

worker: venv ## Start Celery worker
	$(VENV)/bin/celery -A config worker -l info

tailwind: ## Watch and rebuild Tailwind CSS
	npm run tailwind:watch

test: venv ## Run tests with pytest + coverage report
	$(VENV)/bin/pytest --cov=. --cov-report=term-missing

lint: venv ## Lint code with ruff
	$(VENV)/bin/ruff check .

format: venv ## Auto-format code with ruff
	$(VENV)/bin/ruff format .

migrate: venv ## Apply database migrations
	$(PYTHON) manage.py migrate

makemigrations: venv ## Create new migrations
	$(PYTHON) manage.py makemigrations

shell: venv ## Open Django shell
	$(PYTHON) manage.py shell

superuser: venv ## Create a superuser
	$(PYTHON) manage.py createsuperuser

collectstatic: venv ## Collect static files
	$(PYTHON) manage.py collectstatic --noinput

clean: ## Remove cache files, compiled Python, and the SQLite database
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -exec rm -rf {} +
	rm -f db.sqlite3

reset: clean setup ## Full teardown and rebuild (clean + setup)
