# Packaging

Collects all the resources necessary for successfully packaging our rust project for various [targets](https://doc.rust-lang.org/rustc/targets/built-in.html), across different formats.

The main packaging functionality here is exposed via [run.sh](run.sh) script -- please refer to the header there for more details on its usage.

For CI or local use, packaging is best done via the [project Makefile](../Makefile), which has convenient (make) targets defined for doing it against all the supported rustc targets as well as package formats (documented below too).

```bash
make builder-images && make packages # from project root
```
Resulting artifacts will be available in the directory `packaging/out` (relative to project root). Enjoy!

Note: once we have the builder images successfuly pushed to [docker hub](https://hub.docker.com/r/anupdhml/example-builder-rust), just `make packages` will suffice (the images will be pulled in automatically as part of project build).

## Supported Targets

* x86_64-unknown-linux-gnu
* x86_64-alpine-linux-musl

For the list of targets used during project release, please refer to the [project Makefile](../Makefile).

## Supported Formats

* Archive ([tar.gz](https://en.wikipedia.org/wiki/Tar_(computing)) for linux targets)
* [Debian package](https://www.debian.org/doc/debian-policy/ch-binary.html)

For the list of formats used during project release (variable by target), please refer to the [project Makefile](../Makefile).
