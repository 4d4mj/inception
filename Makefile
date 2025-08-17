all: build

build:
	@echo "Creating data directories..."
	@mkdir -p /home/${USER}/data/mysql
	@mkdir -p /home/${USER}/data/wordpress
	@echo "Building and starting containers..."
	@cd srcs && docker compose up -d --build

down:
	@cd srcs && docker compose down

clean: down
	@docker system prune -af
	@docker volume prune -f

fclean: clean
	@sudo rm -rf /home/${USER}/data

re: fclean all

.PHONY: all build down clean fclean re
