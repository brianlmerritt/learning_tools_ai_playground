# Moodle AI Playground - WIP!

## Project Description
The Moodle AI Playground is a docker environment designed for experimenting with Moodle and various AI systems. It integrates Moodle and Moodle-Docker as submodules, facilitating the automatic loading of other Moodle plugins upon request. The AI aspect of the playground includes a series of plugins supporting vector stores and local or remote Large Language Models (LLMs), offering scalable and customizable AI experimentation within Moodle.

### Helper Scripts
Within the `bin` directory, several helper scripts are available to streamline the setup and management of the Moodle AI Playground:

- `moodle_submodules.sh`: Pulls in necessary Moodle plugins and supporting systems, checking out the relevant branch.
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

# edit configs/moodle.yaml and configs/plugins.yaml as needed
./bin/moodle_submodules.sh # This adds submodules and checks out the branch / tag as needed
./bin/moodle_up.sh

# Bring up the plugins

### Play with stuff and see if Moodle installs ok on localhost:8000




./bin/moodle_down.sh

```

## Configuration

Configuration scripts are located in the `configs` directory. These scripts should be updated to reflect your specific setup:

- `moodle.yaml`: Specifies the Moodle submodules required and selects the database engine.
- `plugins.yaml`: Lists the AI submodules required and the method to launch the AI docker plugins.
- `local.yml` : create this and it will be copied to the core\moodle-docker environment

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
- [ ] Lots of stuff no one has even thought of yet

## Known issues

1. You won't be able to push to Moodle core, so any time you run `git submodule update --init --recursive` you should run the `bin\moodle_submodules.sh` script to get the right branches back.

## Acknowledgements
- Place to acknowledge individuals, organizations, or projects that have contributed to the development of the Moodle AI Playground.

