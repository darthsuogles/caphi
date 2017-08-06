#!/bin/bash

export PYTHONPATH=/caffe2/build:$PYTHONPATH 
exec ipython2 -i $@
