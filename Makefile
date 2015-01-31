RVDB-WEB=../rvdb-web	

all: rvdb.tar.gz data/data.json web

rvdb.tar.gz: data/*.sys data/*.vels
	tar -cvzf rvdb.tar.gz data

data/data.json: data/*.sys data/*.vels
	cd scripts; Rscript json.r

web: data/data.json
	cp -R data $(RVDB-WEB)
	cp rvdb.tar.gz $(RVDB-WEB)
