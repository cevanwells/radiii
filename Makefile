.DEFAULT_GOAL := fresh

build:
	docker build -t iii_radius .

up:
	docker-compose up -d

down:
	docker-compose down -v

clean:
	docker rmi iii_radius
	docker volume prune -f

fresh: down clean build up

enter:
	docker exec -it iiiradius_radiusd_1 /bin/sh

logs:
	docker logs -f iiiradius_radiusd_1

nuke:
	docker rm `docker ps -aq`
	docker rmi `docker images -q`
	docker image prune -f
	docker network prune -f