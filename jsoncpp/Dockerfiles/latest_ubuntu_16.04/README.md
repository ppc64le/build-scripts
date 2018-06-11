jsoncpp (package)

#Build and run the container:

$docker build -t jsoncpp .
$docker run --name demo_jsoncpp -i -t jsoncpp /bin/bash

Test the working of Container:

#Create file alice.json with the following contents:

{
    "book":"Alice in Wonderland",
    "year":1865,
    "characters":
    [
        {"name":"Jabberwock", "chapter":1},
        {"name":"Cheshire Cat", "chapter":6},
        {"name":"Mad Hatter", "chapter":7}
    ]
}

#Create file alice.cpp with following contents:

#include <iostream>
#include <fstream>
#include </jsoncpp/dist/json/json.h> // or jsoncpp/json.h , or json/json.h etc.

using namespace std;

int main() {
    ifstream ifs("alice.json");
    Json::Reader reader;
    Json::Value obj;
    reader.parse(ifs, obj); // reader can also read strings
    cout << "Book: " << obj["book"].asString() << endl;
    cout << "Year: " << obj["year"].asUInt() << endl;
    const Json::Value& characters = obj["characters"]; // array of characters
    for (int i = 0; i < characters.size(); i++){
        cout << "    name: " << characters[i]["name"].asString();
        cout << " chapter: " << characters[i]["chapter"].asUInt();
        cout << endl;
    }
}

#Compile it:

   g++ -std=c++11 -o  alice alice.cpp -ljsoncpp
   
#Then run it:

   ./alice

#Output:

Book: Alice in Wonderland
Year: 1865
    name: Jabberwock chapter: 1
    name: Cheshire Cat chapter: 6
    name: Mad Hatter chapter: 7

#Additional examples are available at: https://en.wikibooks.org/wiki/JsonCpp
