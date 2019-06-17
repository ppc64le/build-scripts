
 Build:
   docker build -t eclipse/che-cli .

 use:
    docker run -v $(pwd):/che eclipse/che-cli [command]
