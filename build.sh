#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

DUKTAPE_DIR="${SCRIPT_DIR}/build/duktape"
PROCESS_DIR="${SCRIPT_DIR}/aos/process"
LIBS_DIR="${PROCESS_DIR}/libs"

AO_IMAGE="p3rmaw3b/ao:0.1.2"

# Recreate the libs directory
rm -rf ${LIBS_DIR}
mkdir -p ${LIBS_DIR}

EMXX_CFLAGS="-s MEMORY64=1 -O3 -msimd128 -fno-rtti -flto=full -s BUILD_AS_WORKER=1 -s EXPORT_ALL=1 -s EXPORT_ES6=1 -s MODULARIZE=1 -s NO_EXIT_RUNTIME=1 -Wno-unused-command-line-argument -Wno-experimental"

# Clone llama.cpp if it doesn't exist
rm -rf ${DUKTAPE_DIR}
rm -rf libs
if [ ! -d "${DUKTAPE_DIR}" ]; then \
    mkdir -p ${DUKTAPE_DIR}; \
	curl -L https://github.com/svaarala/duktape/releases/download/v2.7.0/duktape-2.7.0.tar.xz | tar xJf - -C ${DUKTAPE_DIR} --strip-components=1; \
    cp ./inject/Makefile ${DUKTAPE_DIR}/src/Makefile; \
fi

# Build duktape into a static library with emscripten
docker run -v ${SCRIPT_DIR}/build:/build ${AO_IMAGE} sh -c \
		"cd /build/duktape/src && make CC=\"emcc -s MEMORY64=1 -O3 -msimd128 -fno-rtti -flto=full -s BUILD_AS_WORKER=1 -s EXPORT_ALL=1 -s EXPORT_ES6=1 -s MODULARIZE=1 -s NO_EXIT_RUNTIME=1 -Wno-unused-command-line-argument -Wno-experimental\""

# Build duktape into a static library with emscripten
docker run -v ${SCRIPT_DIR}/build:/build ${AO_IMAGE} sh -c \
		"cd /build/duktape-bindings && emcc duktape-bindings.cpp -c -sMEMORY64=1 -o duktape-bindings.o /lua-5.3.4/src/liblua.a -I/lua-5.3.4/src -I/build/duktape/src /build/duktape/src/duktape.a && emar rcs duktape-bindings.so duktape-bindings.o"


cp ${DUKTAPE_DIR}/src/duktape.a ${LIBS_DIR}/duktape.a;
cp ${SCRIPT_DIR}/build/duktape-bindings/duktape-bindings.so ${LIBS_DIR}/duktape-bindings.so

# Fix permissions
sudo chmod -R 777 ${DUKTAPE_DIR}

# Copy config.yml to the process directory
cp ${SCRIPT_DIR}/config.yml ${PROCESS_DIR}/config.yml


# Build the process module
cd ${PROCESS_DIR} 
docker run -e DEBUG=1 --platform linux/amd64 -v ./:/src ${AO_IMAGE} ao-build-module

# Copy the process module to the tests directory
cp ${PROCESS_DIR}/process.wasm ${SCRIPT_DIR}/tests/process.wasm
cp ${PROCESS_DIR}/process.js ${SCRIPT_DIR}/tests/process.js
# cp ${PROCESS_DIR}/process.js ${SCRIPT_DIR}/test-llm/process.js
