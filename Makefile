# picolisp-posixmq Makefile

PIL_MODULE_DIR ?= .modules
REPO_PREFIX ?= https://github.com/aw

# Unit testing
TEST_REPO = $(REPO_PREFIX)/picolisp-unit.git
TEST_DIR = $(PIL_MODULE_DIR)/picolisp-unit/HEAD
TEST_REF = v3.1.0

.PHONY: all sysdefs

all: sysdefs check

$(TEST_DIR):
		mkdir -p $(TEST_DIR) && \
		git clone $(TEST_REPO) $(TEST_DIR) && \
		cd $(TEST_DIR) && \
		git checkout $(TEST_REF)

sysdefs:
		cd /usr/share/picolisp/src64 && \
		$(MAKE) sysdefs || true

check: sysdefs $(TEST_DIR) run-tests

run-tests:
		./test.l
