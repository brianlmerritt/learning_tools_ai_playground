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

## Configuration
Configuration scripts are located in the `configs` directory. These scripts should be updated to reflect your specific setup:

- `moodle.yaml`: Specifies the Moodle submodules required and selects the database engine.
- `plugins.yaml`: Lists the AI submodules required and the method to launch the AI docker plugins.

## License
This project is licensed under the MIT License. For more details, see the LICENSE file in the project repository.

## Contributions
Contributions to the Moodle AI Playground are welcome! If you're interested in contributing, please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or fix.
3. Commit your changes with clear, descriptive messages.
4. Push your branch and submit a pull request.

For more detailed instructions, please refer to [CONTRIBUTING.md](CONTRIBUTING.md) (Note: You'll need to create this file with contribution guidelines).

## Todo
- [ ] List pending tasks or features that are planned or currently in development.

## Acknowledgements
- Place to acknowledge individuals, organizations, or projects that have contributed to the development of the Moodle AI Playground.

