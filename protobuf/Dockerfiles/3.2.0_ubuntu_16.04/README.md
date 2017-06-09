# print protobuf version

docker run -it --rm protobuf --version

# print protobuf help message

docker run -it --rm protobuf --help

# Use current folder for input and output

docker run -it --rm -v $PWD:/src:rw protobuf --cpp_out=. *.proto


