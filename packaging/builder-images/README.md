Docker images used for compilation across various targets in CI builds (or locally if desired). Meant for use with [cross](https://github.com/rust-embedded/cross), but can be used independent of it too.

The images here are picked up via the [cross configuration](../Cross.toml) file at project root, during builds.

If you are changing any of the files here, you will need to rebuild and push the image:

```
# build image for a target
./build_image.sh x86_64-unknown-linux-gnu

# push the image
docker push anupdhml/example-builder-rust:x86_64-unknown-linux-gnu
```

The images are provisoned with the rust version specified in the project [rust-toolchain](../rust-toolchain) file, so the above instructions apply for when we bump the versions there too.
