# Python AI / Machine Learning Platform

Here's a summary of what has been done:

Created a docker-compose.yaml file in the plugins/python_playground directory with the following features:

Environment variables for OPENAI_API_KEY, ANTHROPIC_API_KEY, and HUGGINGFACE_API_TOKEN
Volume mapping from $ROOT/python_playground to /home/pythondev/workspace in the container
User configuration to run as "pythondev"
Created a Dockerfile in the same directory with:

Python 3.9 as the base image
Installation of required AI libraries: llama-index, langchain, langgraph, huggingface (transformers), and ultralytics
Creation of a non-root user "pythondev"
To use this development environment:

Ensure you have Docker and Docker Compose installed on your system.
Navigate to the plugins/python_playground directory in your terminal.
Run the following command to build and start the container:

docker-compose up --build -d

To enter the container and start working, use:

docker-compose exec python_ai_dev bash

You will now be in the container as the "pythondev" user, with all the specified AI libraries installed and ready to use. The $ROOT/python_playground directory is mapped to /home/pythondev/workspace inside the container, so any changes you make will persist on your host machine.