
all:
	mkdir -p results
	psql -t -f make_region.sql|python split.py
	psql -t -f basic.sql|python split.py
