BUILD_NUMBER := $(shell cat BUILD_NUMBER)


dependencies:
	sampctl package ensure


dev:
	sampctl package build --build dev
	$(eval BUILD_NUMBER=$(shell echo $$(($(BUILD_NUMBER)+1))))
	echo -n $(BUILD_NUMBER) > BUILD_NUMBER


prod:
	sampctl package build --build prod
	$(eval BUILD_NUMBER=$(shell echo $$(($(BUILD_NUMBER)+1))))
	echo -n $(BUILD_NUMBER) > BUILD_NUMBER


build:
	docker build -t southclaws/scavengesurvive .

# Compiles required filterscripts
filterscripts:
	pawncc \
		-\;+ \
		-\(+ \
		-\\+ \
		filterscripts/rcon.pwn

	pawncc
		-idependencies/samp-streamer-plugin \
		-idependencies/sscanf \
		-idependencies/SA-MP-FileManager \
		filterscripts/object-loader.pwn


# Runs a Redis container for testing
redis:
	docker run --name redis redis
