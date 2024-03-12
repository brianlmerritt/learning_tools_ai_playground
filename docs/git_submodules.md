# Git Submodules Stuff

## Adding submodules you don't own or appending a repository here

Most plugins for Moodle and AI may belong to other people or teams, and you may not have write access and they might be very upset if you suddenly added docker files and scripts to make them fit here.

Core Moodle also does not use submodules, but most Moodle hosting companies have methods to add and maintain submodules as needed, and the Moodle AI Playground is trying to emulate a simpler version of what they provide.

For the same reason, if you clone a repository here as a subdirectory, that becomes a permanent (until deleted) asset so you won't be able to push changes (yes, via a pull request) her and it makes updating the Moodle AI Playground harder for you.

So we encourage you to use the `moodle.yaml` configs to install moodle plugins, and the `plugins.yaml` configs to indicate what extra you want loaded and where it should go.

If a plugins.yaml config doesn't have a URL that's because it has no repository needed, just a docker-compose.yaml file and some configs maybe

run `./bin/moodle_submodules.sh` or `.bin/plugin_submodules.sh` as needed to install new plugins and ensure they stay on the right branch.

If you ever type `git submodule update --init --recursive` by mistake (and here it is almost always a mistake) just run the above scripts again to put things back to normal.

## Living with submodules

`git submodule` gives you a list of submodules added to the core Moodle AI Playground.  That will include any plugins, but exclude Moodle plugins.

If you run the same from `core/moodle` directory that will show the plugins added to Moodle via the moodle.yaml config

Remember run the shell scripts to put things back to the right branch or tag if things go south

## Removing submodules

There is no git submodules delete command but instead from the root directory you can run 

`git submodule deinit plugins/pluginname/submoduledirectoryname`

and then

`git rm -rf plugins/pluginname/submoduledirectoryname`

For Moodle plugins (for example you might be blocked from upgrading moodle due to the wrong plugin version, location, dependency) do the same but from the `core/moodle` directory.  

Remember to remove them from the moodle.yaml or plugins.yaml files or they will just get added again when you run the shell scripts.

