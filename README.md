# AO-Duktape

## USAGE

### Pull Submodules

We need to pull the latest aos.
```sh
git submodule update --init --recursive
```


### Build

Just run ./build.sh ( This will build the nessasary libraries inject them and compile the wasm)
```sh
./build.sh
```

### Testing

```sh
cd tests
yarn # or npm i
yarn test # or npm run test
```