#!/bin/bash

OS=$(uname -s | tr '[:upper:]' '[:lower:]')

function _log_msg() {
    >&2 printf "[$1]: "; shift
    [[ $# > 0 ]] && >&2 printf "%s" "$@"
}
function quit_with() { _log_msg "ERROR" "$@"; exit; }
function log_info() { _log_msg "INFO" "$@"; }

[ "${OS}" == "darwin" ] || quit_with "only support OSX for the moment"

cp Makefile.config.example _tmp_Makefile.config

function set_build_option() {
    local optName=$1
    local optArgs=$2
    perl -i.bak -pe \
	 "s/^#?\s*(${optName}\s+:=\s+.*)/${optName} := ${optArgs}/" \
	 _tmp_Makefile.config
}

function del_build_option() {
    local optName=$1
    perl -i.bak -pe \
	 "s/^\s*#?\s*${optName}\s+:=\s+.*(\\\\.+)*//sg" \
	 _tmp_Makefile.config    
}

set_build_option "CPU_ONLY" "1"
set_build_option "USE_LMDB" "1"
set_build_option "BLAS" "openblas"
set_build_option "OPENCV_VERSION" "3"
set_build_option "CUSTOM_CXX" "clang++"

# Before removing, combine configs spanning multiple lines
perl -i.bak -pe 's@\\\s*$@@sm' _tmp_Makefile.config

del_build_option "CUDA_ARCH"
del_build_option "CUDA_DIR"
del_build_option "USE_CUDNN"

del_build_option "PYTHON_INCLUDE"
del_build_option "PYTHON_LIB"
del_build_option "TEST_GPUID"
del_build_option "ANACONDA_HOME"
del_build_option "MATLAB_DIR"
