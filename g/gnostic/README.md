Pakckage    : googleapis/gnostic
Version     : v0.5.1
Source repo : https://github.com/googleapis/gnostic
Tested on   : UBI 8.5

Note - Now path for this package is redirected to https://github.com/google/gnostic

1. For requested version 0.5.1 build is failing with below errors on power.
[root@a5009d23d2f3 gnostic@v0.5.1]# make
go generate ./...
go: downloading github.com/docopt/docopt-go v0.0.0-20180111231733-ee0de3bc6815
go: downloading github.com/stoewer/go-strcase v1.2.0
go: downloading github.com/golang/protobuf v1.5.2
go: downloading google.golang.org/protobuf v1.26.0
go: downloading github.com/google/go-cmp v0.5.5
go: module github.com/golang/protobuf is deprecated: Use the "google.golang.org/protobuf" module instead.
go get: installing executables with 'go get' in module mode is deprecated.
        To adjust and download dependencies of the current module, use 'go get -d'.
        To install using requirements of the current module, use 'go install'.
        To install ignoring the current module, use 'go install' with a version,
        like 'go install example.com/cmd@latest'.
        For more information, see https://golang.org/doc/go-get-install-deprecation
        or run 'go help get' or 'go help install'.
go get: upgraded github.com/golang/protobuf v1.4.2 => v1.5.2
go get: upgraded google.golang.org/protobuf v1.23.0 => v1.26.0
protoc-gen-go: invalid Go import path "openapiv2" for "openapiv2/OpenAPIv2.proto"

The import path must contain at least one forward slash ('/') character.

See https://developers.google.com/protocol-buffers/docs/reference/go-generated#package for more information.

--go_out: protoc-gen-go: Plugin failed with status code 1.
protoc-gen-go: invalid Go import path "openapiv3" for "openapiv3/OpenAPIv3.proto"

The import path must contain at least one forward slash ('/') character.

See https://developers.google.com/protocol-buffers/docs/reference/go-generated#package for more information.

--go_out: protoc-gen-go: Plugin failed with status code 1.
protoc-gen-go: invalid Go import path "discovery" for "discovery/discovery.proto"

The import path must contain at least one forward slash ('/') character.

See https://developers.google.com/protocol-buffers/docs/reference/go-generated#package for more information.

--go_out: protoc-gen-go: Plugin failed with status code 1.
protoc-gen-go: invalid Go import path "plugins" for "plugins/plugin.proto"

The import path must contain at least one forward slash ('/') character.

See https://developers.google.com/protocol-buffers/docs/reference/go-generated#package for more information.

--go_out: protoc-gen-go: Plugin failed with status code 1.
protoc-gen-go: invalid Go import path "extensions" for "extensions/extension.proto"

The import path must contain at least one forward slash ('/') character.

See https://developers.google.com/protocol-buffers/docs/reference/go-generated#package for more information.

--go_out: protoc-gen-go: Plugin failed with status code 1.
protoc-gen-go: invalid Go import path "surface" for "surface/surface.proto"

The import path must contain at least one forward slash ('/') character.

See https://developers.google.com/protocol-buffers/docs/reference/go-generated#package for more information.

--go_out: protoc-gen-go: Plugin failed with status code 1.
protoc-gen-go: invalid Go import path "metrics" for "metrics/vocabulary.proto"

The import path must contain at least one forward slash ('/') character.

See https://developers.google.com/protocol-buffers/docs/reference/go-generated#package for more information.

--go_out: protoc-gen-go: Plugin failed with status code 1.
protoc-gen-go: invalid Go import path "metrics" for "metrics/complexity.proto"

The import path must contain at least one forward slash ('/') character.

See https://developers.google.com/protocol-buffers/docs/reference/go-generated#package for more information.

--go_out: protoc-gen-go: Plugin failed with status code 1.
gnostic.go:15: running "./COMPILE-PROTOS.sh": exit status 1
make: *** [Makefile:3: all] Error 1


2. Same problem is observed on Intel as well. 
3. In addition to this there is an open github issue raised by someone in github regarding this build failure.
   Link for the same: https://github.com/google/gnostic/issues/235
4. These build failure are fixed for the latest version 0.6.9