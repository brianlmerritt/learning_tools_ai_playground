# Use an official Python runtime as a parent image
FROM python:3.9-slim-buster

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Create and set the working directory
WORKDIR /home/pythondev/workspace

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd -m -s /bin/bash pythondev

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
    requests \
    llama-index \
    langchain \
    langgraph \
    transformers \
    torch \
    ultralytics

# Change ownership of the working directory to pythondev
RUN chown -R pythondev:pythondev /home/pythondev

# Switch to non-root user
USER pythondev

# Set the default command to bash
CMD ["/bin/bash"]
