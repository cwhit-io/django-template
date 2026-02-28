.PHONY: help install dev worker tailwind test migrate makemigrations shell superuser collectstatic

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Install all Python and Node dependencies
	pip install -r requirements.txt
	npm install

dev: ## Start Daphne ASGI server
	daphne config.asgi:application

worker: ## Start Celery worker
	celery -A config worker -l info

tailwind: ## Watch and rebuild Tailwind CSS
	npm run tailwind:watch

test: ## Run tests with pytest + coverage report
	pytest --cov=. --cov-report=term-missing

migrate: ## Apply database migrations
	python manage.py migrate

makemigrations: ## Create new migrations
	python manage.py makemigrations

shell: ## Open Django shell
	python manage.py shell

superuser: ## Create a superuser
	python manage.py createsuperuser

collectstatic: ## Collect static files
	python manage.py collectstatic --noinput
