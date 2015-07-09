all: app/rvdb.tar.gz app

app/rvdb.tar.gz: data/*.sys data/*.vels R/make.r
	tar -cvzf app/rvdb.tar.gz data

app: app/combined_star_data.rds app/data.json

app/combined_star_data.rds: data/*.sys data/*.vels R/make.r
	cd app; Rscript ../R/make.r

app/data.json: data/*.sys data/*.vels R/make.r
	cd app; Rscript ../R/json.r

