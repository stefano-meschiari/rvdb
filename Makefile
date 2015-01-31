all: archive json

archive:
	tar -cvzf rvdb.tar.gz data

json:
	Rscript scripts/json.r
