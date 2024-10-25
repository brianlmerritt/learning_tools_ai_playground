# Learning Tools AI Playground - WIP!

## Project Description
The Learning Tools AI Playground is a docker environment designed for experimenting with Moodle and various AI systems. It integrates Moodle and Moodle-Docker as submodules, facilitating the automatic loading of other Moodle plugins upon request. The AI aspect of the playground includes a series of plugins supporting vector stores and local or remote Large Language Models (LLMs), offering scalable and customizable AI experimentation within Moodle.

### Helper Scripts
Within the `bin` directory, several helper scripts are available to streamline the setup and management of the Moodle AI Playground:

- `moodle_submodules.sh`: Pulls in necessary Moodle plugins and supporting systems, checking out the relevant branch.  Re-run this script any time you change the moodle.yaml file to bring in the correct repositories and branches.
- `plugin_submodules.sh`: Fetches the required AI plugins, systems, and tools to build the AI playground.
- `moodle_up.sh`: Launches the Moodle docker server and its services.
- `moodle_down.sh`: Stops the Moodle docker server.
- `ai_up.sh`: Activates the AI plugins.
- `ai_down.sh`: Deactivates the AI plugins.

## Installation

For Linux - untested on Mac and Windows systems

```
sudo apt install jq # json parser for batch scripts
git clone https://github.com/brianlmerritt/moodle_ai_playground
cd moodle_ai_playground
pip install -r requirements.txt

# Pull in the core submodules
git submodule update --init --recursive

# edit configs/moodle.yaml and configs/plugins.yaml and setup_environment.sh as needed. Put your OpenAI, Anthropic, and/or HuggingFace keys in the setup_environment.sh file.

# configs/moodle.yaml is to select which Moodle plugins to install.  You can install themes, course formats, activities, blocks, etc.
# configs/plugins.yaml are used to setup the docker AI environment.  You can select which LLM models to run and which vector stores to use.
# Once setup, you can run the following to install the core submodules, the Moodle plugins, and the AI docker plugins

./bin/setup_environment.sh # Note this is .gitignored. Copy ./bin/setup_environment_example.sh and add any AI keys
./bin/moodle_submodules.sh # This adds submodules and checks out the branch / tag as needed
./bin/plugin_submodules.sh # Makes sure a docker-compose.yaml exists for each plugin, or does a git pull if a url is provided.


```

## Configuration

Configuration scripts are located in the `configs` directory. These scripts should be updated to reflect your specific setup:

- `moodle.yaml`: Specifies the Moodle submodules required and selects the database engine.
- `plugins.yaml`: Lists the AI submodules required and the method to launch the AI docker plugins.
- `local.yml` : create this and it will be copied to the core\moodle-docker environment
- `setup_environment.sh` : Put your OpenAI, Anthropic, and/or HuggingFace keys in this file.  Note Ollama is run locally and uses your GPU if available, but of course OpenAI, Anthropic, and HuggingFace are external services.

### setup_environment.sh notes ###

If you are using an NVidia GPU, set export USE_NVIDIA=true, otherwise false.  You *must* also use the correct ollama docker container in plugins.yaml.  Use the docker-compose-nvidia.yaml file to launch the Ollama GPU enabled docker containers.  Otherwise use docker-compose-cpu.yaml.

If you want to use SSL for the Moodle host, set export MOODLE_DOCKER_SSL_OVERRIDE=true.  Note that this will override the default port of 8000 to 8443.  You will also need to update the MOODLE_DOCKER_WEB_PORT in setup_environment.sh to 8443.  You will also have to add the appropriate ssl certificates to the core/nginx_proxy root folder.

## Operation

```
# Bring up Moodle
./bin/moodle_up.sh # Brings up Moodle docker

# Next perform a Moodle install. Note that it is on localhost:8000, but we do not expose this port outside the host.

http://localhost:8000/ # And do a normal Moodle install.  The database is persistent across runs.

# Bring up AI related docker instances
./bin/ai_up.sh # Brings up AI related docker instances

### Play with stuff and see if Moodle installs ok on localhost:8000

./bin/python_ai_playground.sh # Sets up a terminal window into the Python docker environment.  Put your code in python_playground directory to run here.
python3 check_ai_connections.py # Test the connection to the various AI systems inside the python docker container

### Setup Moodle pluginsto use the AI playground.  
# As standard that would include a SOLR or ElasticSearch vector store and an LLM such as OpenAI, Anthropic and anything supported by Ollama or HuggingFace
# Port mappings are:
# 8000 - Moodle
# 8983 - SOLR
# 9200 - ElasticSearch
# 11434 - Ollama
# 8081 - Weaviate
# 9998 - Tika
# 5601 - Kibana (for ElasticSearch)
# Make sure the appropriate Moodle plugins are installed, and then setup Moodle on localhost:8000 to connect to the above services.


# Shut down Moodle and the AI docker plugins
./bin/ai_down.sh
./bin/moodle_down.sh

```

## License
This project is licensed under the MIT License. For more details, see the LICENSE file in the project repository.

## Contributions
Contributions to the Moodle AI Playground are welcome! If you're interested in contributing, please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or fix.
3. Commit your changes with clear, descriptive messages.
4. Push your branch and submit a pull request.

For more detailed instructions, please refer to [CONTRIBUTING.md](CONTRIBUTING.md)

## Todo
- [ ] Get minimum AI system of SOLR and ElasticSearch running and integrated with Moodle environment
- [ ] Get working Ollama and/or text generation webui install working
- [ ] Setup Moodle environment to test search (and export to vector stores)
- [ ] Setup Moodle course restore so course backups can be restored in the AI playground and used to test the AI and RAG system
- [ ] Setup RAG system to work with Moodle and SOLR or ElasticSearch vector stores
- [ ] Setup Moodle content export to Weaviate and build Multi-modal RAG system


## Known issues

1. The Moodle part of the AI playground uses GIT submodules.  If you change any code inside of core/moodle you will not be able to push to Moodle core.  By it's nature, git submodules can get confused, and do not understand the moodle.yaml configuration, so any time you run `git submodule update --init --recursive` you should run the `./bin\moodle_submodules.sh` script to get the right branches back.

## Acknowledgements
- Place to acknowledge individuals, organizations, or projects that have contributed to the development of the Moodle AI Playground.

