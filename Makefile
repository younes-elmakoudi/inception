NAME = inception
COMPOSE = docker compose -f srcs/docker-compose.yml
DATA_DIR = /home/$(shell whoami)/data

all: up

up: data_dirs
	$(COMPOSE) up --build -d

down:
	$(COMPOSE) down

stop:
	$(COMPOSE) stop

start:
	$(COMPOSE) start

restart: down up

clean: down
	docker system prune -af

fclean: clean
	sudo rm -rf $(DATA_DIR)

re: fclean all

data_dirs:
	mkdir -p $(DATA_DIR)/mariadb
	mkdir -p $(DATA_DIR)/wordpress

.PHONY: all up down stop start restart clean fclean re data_dirs