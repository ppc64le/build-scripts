UUID

It is a go library

Building and running the container:

$docker build -t uuid .
$docker run -it --name=<name> uuid 

Testing the Container:

Inside the container, create a sample test.go file as follows:

___________________________________________________
package main
import "github.com/twinj/uuid"
import "fmt"
func main() {
id, _ := uuid.Parse("6ba7b810-9dad-11d1-80b4-00c04fd430c8")

if uuid.Equal(id, uuid.NameSpaceDNS) {
    fmt.Println("Alas these are equal")
}
// Default Format is FormatCanonical
fmt.Println(uuid.Formatter(id, uuid.FormatCanonicalCurly))

uuid.SwitchFormat(uuid.FormatCanonicalBracket)
}
___________________________________________________

Now run the file as follows:
$go run test.go

OUTPUT:

Alas these are equal
{6ba7b810-9dad-11d1-80b4-00c04fd430c8}

