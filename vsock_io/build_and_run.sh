#!/bin/bash -ex
root_dir=$(readlink -f $(dirname "${BASH_SOURCE[0]}"))/..
cd ${root_dir}

# Cleaning up environment
rm -f ./vsock-sample
rm -f ./vsock_sample_client.eif

# Build sample
pushd vsock_sample/rs
cargo build
popd

# Start server
pushd vsock_sample/rs
cargo run -- server --port 5005 &
server_pid=$!
echo server: ${server_pid}
popd

# Build eif image
cp vsock_sample/rs/target/debug/vsock-sample vsock_io/
nitro-cli build-enclave --docker-dir ${root_dir}/vsock_io --docker-uri vsock-sample-client --output-file vsock_sample_client.eif

# Configure parent
nitro-cli-config -t 2 -m 512 || true

# Run enclave
nitro-cli run-enclave --eif-path vsock_sample_client.eif --cpu-count 2 --memory 512 --debug-mode

# Sleep a while to let the enclave start up and execute
sleep 5s

# Terminate all enclaves
nitro-cli terminate-enclave --all

#Kill server
echo "Killing server"
kill ${server_pid}
