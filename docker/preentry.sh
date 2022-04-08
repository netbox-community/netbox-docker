#!/bin/bash
set -e

# Example of how to activate a development plugin

# echo -e "installing custom plugin"
# source /opt/netbox/venv/bin/activate
# cd /opt/plugin_source
# python3 setup.py develop
# echo -e "finished installing custom plugin"


# follow on scripts expect this to be the current dir. 
# uncomment if you have changed directory
# cd /opt/netbox/netbox
exec "$@"
