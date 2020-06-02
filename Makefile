RELEASE_TARGETS := \
	x86_64-unknown-linux-gnu \
	x86_64-alpine-linux-musl \
	# fails on snmalloc builds currently so disabled
	# TODO if we fix this, we don't need the alpine specifc target above for musl builds
	#x86_64-unknown-linux-musl \

help:
	@echo "This makefile wraps the tasks:"
	@echo "  image                - build the docker image"
	@echo "  builder-image-TARGET - build the (builder) docker image used for building against the specified TARGET"
	@echo "  builder-images       - build all the (builder) docker images used for building against the release targets"
	@echo "  build-TARGET         - build for the specified TARGET"
	@echo "  builds               - build for all the release targets"
	@echo "  archive-TARGET       - package release archive for the specified TARGET"
	@echo "  archives             - package release archive for all the release targets"
	@echo "  packages             - package (across applicable formats) for all the release targets"

image:
	# TODO
	docker-compose build

# eg: builder-image-x86_64-unknown-linux-gnu
builder-image-%:
	@echo ""
	./packaging/builder-images/build_image.sh $*

builder-images:
	make $(foreach target,$(RELEASE_TARGETS),builder-image-$(target))

# eg: build-x86_64-unknown-linux-gnu
build-%:
	@echo ""
	./packaging/cross_build.sh $*

builds:
	make $(foreach target,$(RELEASE_TARGETS),build-$(target))

# eg: archive-x86_64-unknown-linux-gnu
archive-%: build-%
	@echo ""
	./packaging/run.sh -f archive $*

archives:
	make $(foreach target,$(RELEASE_TARGETS),archive-$(target))

# package applicable formats for each release target
packages: builds
	@# For x86_64, packaging built on top of glibc based binaries is our primary
	@# means of distribution right now. Using musl targets here would give us
	@# fully static binaries (for easier distribution), but we are seeing up to
	@# 25% slowdown for some of our benchmarks with musl builds. So we stick with
	@# gnu builds for now.
	@echo ""
	./packaging/run.sh -f archive,deb x86_64-unknown-linux-gnu
	@echo ""
	./packaging/run.sh -f archive     x86_64-alpine-linux-musl
