# Working temporary directory

## Use of working temp dir

1. Does not appear in git, so knock yourself out
1. But first, run `./bin/moodle_submodules.sh` and `./bin/moodle_up.sh` and `./bin/ai_up.sh` to get everything up
1. Git clone from project root what ever you need as a submodule inside this directory `git submodule add url_to_submodule plugins/working_temp/nameofsubmoduledir`
1. Add docker-compose and Dockerfile(s) here as needed, away from the submodule (or just add docker-compose.yaml if you don't need a submodule above - see ollama)
1. Use `git submodule deinit plugins/working_temp/nameofsubmoduledir` and `git rm -rf plugins/working_temp/nameofsubmoduledir` to remove later

## Example use case

```
# run the shell scripts above
git submodule add https://github.com/jaluoma/pruju-ai.git plugins/working_temp/prujuai
# Add docker-compose.yaml in this directory, and any necessary configs and Dockerfiles
# Test it, debug it, etc by going `docker compose up -d` in this directory
# Add the docker-compose.yaml and other files to a more appropriate directory such as prujuai
# Add the new plugin to plugins.yaml and plugins_examples.yaml
# Decommission working_temp ready for next item
git submodule deinit plugins/working_temp/prujuai
git rm -rf plugins/working_temp/prujuai

```