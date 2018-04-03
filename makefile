BUILD_NUMBER := $(shell cat BUILD_NUMBER)


dependencies:
	sampctl package ensure

dev:
	sampctl package build --buildFile BUILD_NUMBER dev

prod:
	sampctl package build prod

build:
	docker build -t southclaws/scavengesurvive .


# Runs a Redis container for testing
redis:
	docker run --name redis redis
