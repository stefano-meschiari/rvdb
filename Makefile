all: rvdb.tar.gz app

rvdb.tar.gz: data/*.sys data/*.vels
	tar -cvzf rvdb.tar.gz data

app: app/combined_star_data.rds app/data.json

app/combined_star_data.rds: data/*.sys data/*.vels
	cd app; Rscript ../R/make.r

app/data.json: data/*.sys data/*.vels
	cd app; Rscript ../R/json.r

