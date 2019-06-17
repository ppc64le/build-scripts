 Initializes an empty directory with the templates needed to configure and run Che.

 build:
   docker build -t eclipse/che-init:<version> .

 use (to copy files onto folder):
   docker run -v $(pwd):/che eclipse/che-init:<version>

 use (to run puppet config):
   docker run <puppet-mounts> --entrypoint=/usr/bin/puppet eclipse/che-init:<version> apply <puppet-apply-options>
