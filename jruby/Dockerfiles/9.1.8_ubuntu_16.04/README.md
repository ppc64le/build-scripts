Create a Dockerfile in using jruby image

FROM jruby:latest

CMD ["./your-daemon-or-script.rb"]

$ docker build -t my-ruby-app .

$ docker run -it --name my-running-script my-ruby-app

Run a single Ruby script

For many simple, single file projects, you may find it inconvenient to write a complete Dockerfile. In such cases, you can run a Ruby script by using the Ruby Docker image directly:

$ docker run -it --rm --name my-running-script -v "$PWD":/usr/src/myapp -w /usr/src/myapp jruby:latest jruby your-daemon-or-script.rb

