.DEFAULT_GOAL := fresh

build:
	docker build -t radiii .

up:
	docker-compose up -d

down:
	docker-compose down -v

clean:
	docker rmi radiii
	docker volume prune -f

fresh: down clean build up

enter:
	docker exec -it radiii_radiusd_1 /bin/sh

logs:
	docker logs -f radiii_radiusd_1

nuke:
	docker rm `docker ps -aq`
	docker rmi `docker images -q`
	docker image prune -f
	docker network prune -f