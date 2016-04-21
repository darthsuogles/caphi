#!/bin/bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export PYTHONPATH="$PYTHONPATH:$script_dir/python"
exec ipython --pylab "$@"
