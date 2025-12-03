# ===========================
# STAGE 1 — Build PyTorch
# ============================
FROM ubuntu:24.04 AS builder
WORKDIR /opt
RUN apt update && apt install -y  wget 
RUN wget https://raw.githubusercontent.com/ppc64le/build-scripts/66a0fa45084c5901ba4c7cf648989e34101b868f/t/torchvision/torchvision_0.22.1_ubuntu_24.04.sh && bash torchvision_0.22.1_ubuntu_24.04.sh

# ============================
# STAGE 2 — Runtime Image
# ============================
FROM ubuntu:24.04 AS runtime

ENV DEBIAN_FRONTEND=noninteractive
ENV PIP_BREAK_SYSTEM_PACKAGES=1

# Install only runtime dependencies
RUN apt update && apt install -y \
    python3 python3-pip libglib2.0-0 libsm6 libxrender1 libxext6 libopenblas-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

# Copy PyTorch and TorchVision builds from the builder stage
COPY --from=builder /usr/lib/powerpc64le-linux-gnu/libpng16.so /usr/lib/powerpc64le-linux-gnu/libpng16.so
COPY --from=builder /usr/lib/powerpc64le-linux-gnu/libprotobuf.so.32 /usr/lib/powerpc64le-linux-gnu/libprotobuf.so.32
COPY --from=builder /usr/local/lib /usr/local/lib
COPY --from=builder /opt/pytorch/vision/torchvision/csrc /opt/pytorch/vision/torchvision/csrc
COPY --from=builder /opt/pytorch/pytorch/LICENSE /opt/pytorch/pytorch/LICENSE
COPY --from=builder /opt/pytorch/pytorch/torch/csrc/jit/codegen /opt/pytorch/pytorch/torch/csrc/jit/codegen

# Set default command
CMD ["/bin/bash"]

