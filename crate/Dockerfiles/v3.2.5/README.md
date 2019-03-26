# Note

The elasticsearch-6.5.1-SNAPSHOT.jar should be copied from the image built using Dockerfile.elasticsearch.
```docker cp <container-id>:/usr/share/elasticsearch/lib/elasticsearch-6.5.1-SNAPSHOT.jar .```

Once copied convert the jar to zip and use it to build the crate image.