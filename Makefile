# The default target of this Makefile is...
all::

# Development
# -----------
# make test     # unit tests
# make doc      # build docs
# make flake8   # style check
# make pyint3k  # python2/3 compatibility checks
# make pylint   # full pylint check
#               # TODO pylint config, tox, yapf, others?
# Release Prep
# ------------
# make pot      # update main translation template
# make po       # merge translations
#
# Installation
# ------------
# make prefix=<path> install
# DESTDIR is also supported.
#
# To disable distutil's replacement of "#!/usr/bin/env python" with
# the path to the build environment's python, pass USE_ENV_PYTHON=1
# when invoking make.

# The external commands used by this Makefile are...
CTAGS = ctags
CP = cp
FIND = find
FLAKE8 = flake8
GIT = git
GZIP = gzip
LN = ln
LN_S = $(LN) -s -f
MARKDOWN = markdown
MKDIR_P = mkdir -p
PIP = pip
PYLINT = pylint
PYTHON = python
PYTEST ?= $(PYTHON) -m pytest
RM = rm -f
RM_R = rm -fr
RMDIR = rmdir
TAR = tar

# Flags
# -----
# "make V=1" increases verbosity
# "make test V=2" increases test verbosity
# "make pylint color=1" enables colorized pylint output
# "make test flags={-x,--exitfirst}" exits on the first test failure
ifdef V
    VERBOSE = --verbose
    ifeq ($(V),2)
        TEST_VERBOSE = --verbose
    endif
else
    QUIET = --quiet
endif
PYTEST_FLAGS = $(QUIET) $(TEST_VERBOSE) --doctest-modules
FLAKE8_FLAGS = --max-line-length=80 --statistics --doctests --format=pylint
PYLINT_FLAGS = --rcfile=.pylintrc
ifdef color
    PYLINT_FLAGS += --output-format=colorized
endif
ifdef flags
    PYTEST_FLAGS += $(flags)
endif

# These values can be overridden on the command-line or via config.mak
prefix = $(HOME)
bindir = $(prefix)/bin
datadir = $(prefix)/share/git-cola
coladir = $(datadir)/lib
hicolordir = $(prefix)/share/icons/hicolor/scalable/apps
# DESTDIR =

cola_base := git-cola
cola_app_base= $(cola_base).app
cola_app = $(CURDIR)/$(cola_app_base)
cola_version = $(shell $(PYTHON) bin/git-cola version --brief)
cola_dist := $(cola_base)-$(cola_version)

SETUP ?= $(PYTHON) setup.py

build_args += build
ifdef USE_ENV_PYTHON
    build_args += --use-env-python
endif

install_args += install
install_args += --prefix="$(prefix)"
install_args += --force
install_args += --install-scripts="$(bindir)"
install_args += --record=build/MANIFEST
install_args += --install-lib="$(coladir)"
ifdef DESTDIR
    install_args += --root="$(DESTDIR)"
    export DESTDIR
endif
export prefix

# If NO_VENDOR_LIBS is specified on the command line then pass it to setup.py
ifdef NO_VENDOR_LIBS
    install_args += --no-vendor-libs
endif

PYTHON_DIRS = cola
PYTHON_DIRS += test

ALL_PYTHON_DIRS = $(PYTHON_DIRS)
ALL_PYTHON_DIRS += extras

PYTHON_SOURCES = bin/git-cola
PYTHON_SOURCES += bin/git-dag
PYTHON_SOURCES += share/git-cola/bin/git-xbase
PYTHON_SOURCES += setup.py

# User customizations
-include config.mak

all:: build
.PHONY: all

build_version:
	@GIT=$(GIT) ./extras/generate-build-version.sh 2>/dev/null || true
.PHONY: build_version

build: build_version
	$(SETUP) $(QUIET) $(VERBOSE) $(build_args)
.PHONY: build

install: all
	$(SETUP) $(QUIET) $(VERBOSE) $(install_args)
	$(MKDIR_P) "$(DESTDIR)$(hicolordir)"
	$(LN_S) "$(datadir)/icons/git-cola.svg" \
		"$(DESTDIR)$(hicolordir)/git-cola.svg"
	$(LN_S) git-cola "$(DESTDIR)$(bindir)/cola"
	$(RM_R) "$(DESTDIR)$(coladir)/git_cola"*
	$(RM_R) git_cola.egg-info

# Maintainer's dist target
dist:
	$(GIT) archive --format=tar --prefix=$(cola_dist)/ HEAD^{tree} | \
		$(GZIP) -f -9 - >$(cola_dist).tar.gz

doc:
	$(MAKE) -C share/doc/git-cola all

html:
	$(MAKE) -C share/doc/git-cola html

man:
	$(MAKE) -C share/doc/git-cola man

install-doc:
	$(MAKE) -C share/doc/git-cola install

install-html:
	$(MAKE) -C share/doc/git-cola install-html

install-man:
	$(MAKE) -C share/doc/git-cola install-man

uninstall:
	$(RM) "$(DESTDIR)$(prefix)"/bin/git-cola
	$(RM) "$(DESTDIR)$(prefix)"/bin/git-dag
	$(RM) "$(DESTDIR)$(prefix)"/bin/cola
	$(RM) "$(DESTDIR)$(prefix)"/share/applications/git-cola.desktop
	$(RM) "$(DESTDIR)$(prefix)"/share/applications/git-cola-folder-handler.desktop
	$(RM) "$(DESTDIR)$(prefix)"/share/applications/git-dag.desktop
	$(RM) "$(DESTDIR)$(prefix)"/share/appdata/git-dag.appdata.xml
	$(RM) "$(DESTDIR)$(prefix)"/share/appdata/git-cola.appdata.xml
	$(RM) "$(DESTDIR)$(prefix)"/share/icons/hicolor/scalable/apps/git-cola.svg
	$(RM_R) "$(DESTDIR)$(prefix)"/share/doc/git-cola
	$(RM_R) "$(DESTDIR)$(prefix)"/share/git-cola
	$(RM) "$(DESTDIR)$(prefix)"/share/locale/*/LC_MESSAGES/git-cola.mo
	-$(RMDIR) "$(DESTDIR)$(prefix)"/share/applications 2>/dev/null
	-$(RMDIR) "$(DESTDIR)$(prefix)"/share/appdata 2>/dev/null
	-$(RMDIR) "$(DESTDIR)$(prefix)"/share/doc 2>/dev/null
	-$(RMDIR) "$(DESTDIR)$(prefix)"/share/locale/*/LC_MESSAGES 2>/dev/null
	-$(RMDIR) "$(DESTDIR)$(prefix)"/share/locale/* 2>/dev/null
	-$(RMDIR) "$(DESTDIR)$(prefix)"/share/locale 2>/dev/null
	-$(RMDIR) "$(DESTDIR)$(prefix)"/share/icons/hicolor/scalable/apps 2>/dev/null
	-$(RMDIR) "$(DESTDIR)$(prefix)"/share/icons/hicolor/scalable 2>/dev/null
	-$(RMDIR) "$(DESTDIR)$(prefix)"/share/icons/hicolor 2>/dev/null
	-$(RMDIR) "$(DESTDIR)$(prefix)"/share/icons 2>/dev/null
	-$(RMDIR) "$(DESTDIR)$(prefix)"/share 2>/dev/null
	-$(RMDIR) "$(DESTDIR)$(prefix)"/bin 2>/dev/null
	-$(RMDIR) "$(DESTDIR)$(prefix)" 2>/dev/null

test: all
	$(PYTEST) $(PYTEST_FLAGS) $(PYTHON_DIRS)

coverage:
	$(PYTEST) $(PYTEST_FLAGS) --cov=cola $(PYTHON_DIRS)

clean:
	$(FIND) $(ALL_PYTHON_DIRS) -name '*.py[cod]' -print0 | xargs -0 rm -f
	$(RM_R) build dist tags git-cola.app
	$(RM_R) share/locale
	$(MAKE) -C share/doc/git-cola clean

tags:
	$(FIND) $(ALL_PYTHON_DIRS) -name '*.py' -print0 | xargs -0 $(CTAGS) -f tags

# Update i18n files
i18n: pot mo

pot:
	$(SETUP) build_pot --build-dir=po --no-lang
.PHONY: pot

po:
	$(SETUP) build_pot --build-dir=po
.PHONY: po

mo:
	$(SETUP) build_mo --force
.PHONY: mo

git-cola.app:
	$(MKDIR_P) $(cola_app)/Contents/MacOS
	$(MKDIR_P) $(cola_app)/Contents/Resources
	$(CP) contrib/darwin/Info.plist contrib/darwin/PkgInfo \
	$(cola_app)/Contents
	$(CP) contrib/darwin/git-cola $(cola_app)/Contents/MacOS
	$(CP) contrib/darwin/git-cola.icns $(cola_app)/Contents/Resources
	$(MAKE) prefix=$(cola_app)/Contents/Resources install install-doc
.PHONY: git-cola.app

app-tarball: git-cola.app
	$(TAR) czf $(cola_dist).app.tar.gz $(cola_app_base)

# Preview the markdown using "make README.html"
%.html: %.md
	$(MARKDOWN) $< >$@

flake8:
	$(FLAKE8) $(FLAKE8_FLAGS) $(PYTHON_SOURCES) $(PYTHON_DIRS)

pylint3k:
	$(PYLINT) $(PYLINT_FLAGS) --py3k $(flags) \
	$(PYTHON_SOURCES) $(ALL_PYTHON_DIRS)

pylint:
	$(PYLINT) $(PYLINT_FLAGS) $(flags) \
	$(PYTHON_SOURCES) $(ALL_PYTHON_DIRS)

pylint-check:
	$(PYLINT) $(PYLINT_FLAGS) $(flags) $(file)

requirements:
	$(PIP) install --requirement requirements/requirements.txt

requirements-dev:
	$(PIP) install --requirement requirements/requirements-dev.txt
