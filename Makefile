.DEFAULT_GOAL := help

include .env
export

database_name = practice_service
DOCKER_COMP = docker compose -f docker-compose.yml
EXEC = $(DOCKER_COMP) exec backend_django
MANAGER = $(EXEC) python manage.py
POSTGRES_CONT = $(DOCKER_COMP) exec postgres
DEFAULT_IMAGES = practice_backend

help:
	@echo "  Availible commands:"
	@echo "  help    - Показать это сообщение"
	@echo "  shell   - Запустить Django shell (python manage.py shell)"
	@echo "  up      - Запустить все контейнеры в фоновом режиме"
	@echo "  build   - Собрать образы Docker"

# ---------- Docker Compose ----------
up:
	@$(DOCKER_COMP) up -d

build:
	@$(DOCKER_COMP) build

up-debug:
	@$(DOCKER_COMP) up

down:
	@$(DOCKER_COMP) down --remove-orphans

full-restart: down up

clean:
	@$(DOCKER_COMP) down
	@docker rmi $(DEFAULT_IMAGES) || exit 0;

full-clean:
	@$(DOCKER_COMP) down --volumes
	@docker rmi $(DEFAULT_IMAGES) || exit 0;

rebuild: clean build

update: rebuild up

# ---------- Docker containers ----------
postgres:
	@$(POSTGRES_CONT) psql -U $(POSTGRES_USER) -w $(POSTGRES_PASSWORD) -d $(database_name)

download-dump:
	@echo "Dumping to $(name)..."
	@$(POSTGRES_CONT) pg_dump -U $(POSTGRES_USER) -Fc $(database_name) > $(name)

download-text-dump:
	@echo "Dumping to $(name)..."
	@$(POSTGRES_CONT) pg_dump -U $(POSTGRES_USER) -d $(database_name) > $(name)

upload-dump:
	@echo "Recreating '$(database_name)' database..."
	@$(POSTGRES_CONT) psql -U $(POSTGRES_USER) -d postgres -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '$(database_name)';"
	@$(POSTGRES_CONT) psql -U $(POSTGRES_USER) -d postgres -c "DROP DATABASE IF EXISTS $(database_name);"
	@$(POSTGRES_CONT) psql -U $(POSTGRES_USER) -d postgres -c "CREATE DATABASE $(database_name);"
	@echo "Applying $(name) dump..."
	@$(POSTGRES_CONT) bash -c "pg_restore -e -v -U $(POSTGRES_USER) -Fc --no-owner --no-privileges -d $(database_name) /dump/$(name)"

upload-text-dump:
	@echo "Recreating '$(database_name)' database..."
	@$(POSTGRES_CONT) psql -U $(POSTGRES_USER) -d postgres -c "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '$(database_name)';"
	@$(POSTGRES_CONT) psql -U $(POSTGRES_USER) -d postgres -c "DROP DATABASE IF EXISTS $(database_name);"
	@$(POSTGRES_CONT) psql -U $(POSTGRES_USER) -d postgres -c "CREATE DATABASE $(database_name);"
	@echo "Applying $(name) dump..."
	@$(POSTGRES_CONT) bash -c "psql -e -v -U $(POSTGRES_USER) -d $(database_name) -f /dump/$(name)"


# ---------- DJANGO ----------
migrations:
	@$(MANAGER) makemigrations $(ARGS)

migrate:
	@$(MANAGER) migrate $(ARGS)

create-user:
	@$(MANAGER) createsuperuser --noinput

shell:
	@$(MANAGER) shell
