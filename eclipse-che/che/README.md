 To build it, run in the repository root:
  `docker build -t eclipse/che-server .`

 To run it:
  docker run --net=host \
             --name che \
             -v /var/run/docker.sock:/var/run/docker.sock \
             -v /home/user/che/lib:/home/user/che/lib-copy \
             -v /home/user/che/workspaces:/home/user/che/workspaces \
             -v /home/user/che/storage:/home/user/che/storage \
             eclipse/che-server
