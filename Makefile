up:
	docker compose -f srcs/docker-compose.yml --env-file srcs/.env up --build -d

down:
	docker compose -f srcs/docker-compose.yml down

re: down up
.PHONY: up down re