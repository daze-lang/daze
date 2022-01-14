main:
	rm -rf ./bin && mkdir ./bin && v . && mv ./daze ./bin/daze

run:
	./bin/daze

build-and-run:
	make clean && make && ./bin/daze build demo/lang.daze && ./lang

changelog:
	git cliff > CHANGELOG.md

test:
	cd tests && sudo v test .

clean:
	find . -maxdepth 1 -type f -executable -exec rm {} +