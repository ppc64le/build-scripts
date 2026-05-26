## Build
 
```bash
docker build -t agno:latest .
```
 
---
 
## Run
 
```bash
docker run -it agno:latest
```
 
---

## Using the Container
 
> **Note:** The container drops you into a pre-configured `uv` virtual environment located at `/build/agno/.venv`. You are free to install any additional dependencies as needed:
>
> - **System packages** (e.g. compilers, libraries):
>   ```bash
>   yum install <package-name>
>   ```
> - **Python packages** (installed into the agno venv):
>   ```bash
>   uv pip install <package-name>
>   ```
 
To see all available agno CLI commands, run:
 
```bash
agno --help
```
 
---