#!/bin/bash

_bsd_="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

which ipython3 &>/dev/null || pip3 install ipython

export PYTHONPATH="$PYTHONPATH:${_bsd_}/python"
exec ipython3 --pylab "$@"
