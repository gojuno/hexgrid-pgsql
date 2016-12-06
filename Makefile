SRC_DIR			= $(shell pwd)
BRANCH			= $(shell git rev-parse --abbrev-ref HEAD)
EXTENSION		= hexgrid
EXTVERSION		= $(shell \
					grep default_version $(EXTENSION).control | \
					sed -e "s/default_version[[:space:]]*=[[:space:]]*'\([^']*\)'/\1/")
DATA 			= _build/$(EXTENSION)--$(EXTVERSION).sql
EXTRA_CLEAN 	= _build/$(EXTENSION)--$(EXTVERSION).sql
DOCS			= $(wildcard doc/*.md)

PG_CONFIG		= pg_config
PG_VERSION		= $(shell $(PG_CONFIG) --version|grep -o "[0-9].[0-9].[0-9]")
IS_COMPATIBLE	= $(shell if [ "$(PG_VERSION)" \> "9.6.0" ]; then echo 'ok'; else echo 'no'; fi)

PGXS 			= $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

ifeq ($(IS_COMPATIBLE),no)
$(error "Minimum version of PostgreSQL required is 9.6.0 (current $(PG_VERSION))")
endif


all: _build/$(EXTENSION)--$(EXTVERSION).sql

_build/$(EXTENSION)--$(EXTVERSION).sql: $(sort $(wildcard sql/*.sql))
	mkdir -p _build
	cat $^ > $@

pack:
	git archive --format zip \
		--prefix=$(EXTENSION)-$(EXTVERSION)/ \
		--output $(EXTENSION)-$(EXTVERSION).zip \
		$(BRANCH)

checkzip:
	pgxn check ./$(EXTENSION)-$(EXTVERSION).zip
