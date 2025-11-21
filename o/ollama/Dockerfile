# Use UBI 9.5 as base image
FROM registry.access.redhat.com/ubi9/ubi:9.5

# Set working directory
WORKDIR /opt/ollama

# Copy the built Ollama directory into the container
COPY ./ollama/ .

# Expose the default Ollama API port
EXPOSE 11434

# Set binary permissions to executable 
RUN chmod +x ./ollama
ENV OLLAMA_HOST=0.0.0.0:11434
ENV LD_LIBRARY_PATH=/opt/ollama/build/lib/ollama

# Start Ollama on container run
CMD ["./ollama", "serve"]
