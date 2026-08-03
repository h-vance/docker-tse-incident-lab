.PHONY: up apply verify reset down ticket answer test incident-1 incident-2 incident-3

up:
	docker compose up -d --build

apply:
	docker compose up -d --build --force-recreate

verify:
	bash scripts/verify.sh

reset:
	bash scripts/lab.sh reset

down:
	docker compose down --remove-orphans

ticket:
	bash scripts/lab.sh ticket

answer:
	bash scripts/lab.sh answer

test:
	bash scripts/test_all.sh

incident-1:
	bash scripts/lab.sh start 1

incident-2:
	bash scripts/lab.sh start 2

incident-3:
	bash scripts/lab.sh start 3
