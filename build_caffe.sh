#!/bin/bash

OS=$(uname -s | tr '[:upper:]' '[:lower:]')

function _log_msg() {
    >&2 printf "[$1]: "; shift
    [[ $# > 0 ]] && >&2 printf "%s" "$@"
}
function quit_with() { _log_msg "ERROR" "$@"; exit; }
function log_info() { _log_msg "INFO" "$@"; }

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
set_build_option "USE_LEVELDB" "0"
set_build_option "BLAS" "open"
set_build_option "OPENCV_VERSION" "3"
set_build_option "CUSTOM_CXX" "clang++"
set_build_option "WITH_PYTHON_LAYER" "1"

# Before removing, combine configs spanning multiple lines
perl -i.bak -pe 's@^(.*)\s*\\$@$1`#=LNCMB=#`\\@m' _tmp_Makefile.config
perl -i.bak -pe 's@\\\s*$@@m' _tmp_Makefile.config

#del_build_option "CUDA_ARCH"
del_build_option "CUDA_DIR"
del_build_option "USE_CUDNN"

del_build_option "PYTHON_INCLUDE"
del_build_option "PYTHON_LIB"
del_build_option "TEST_GPUID"
del_build_option "ANACONDA_HOME"
del_build_option "MATLAB_DIR"
del_build_option "INCLUDE_DIRS"
del_build_option "LIBRARY_DIRS"

# Restore previously combined lines
perl -i.bak -pe 's@`#=LNCMB=#`@\\\n@g' _tmp_Makefile.config

# Add some additional configs to the end
[ "${OS}" == "darwin" ] || quit_with "only support OSX for the moment"
function get_pkg { 
    local _pkg="$1"; shift;
    local _opt="$@"
    set -ex
    if [ -n "${_opt}" ]; then
        brew upgrade "${_pkg}" \
            || brew install "${_pkg}" "${_opt}" \
            || brew reinstall "${_pkg}" "${_opt}"
    else
        brew upgrade "${_pkg}" \
            || brew install "${_pkg}" \
            || brew reinstall "${_pkg}"
    fi
    unset
}
function get_pkgs { 
    for _i_pkg in $@; do get_pkg "${_i_pkg}"; done; 
}
get_pkgs gflags glog pkg-config
get_pkg boost-python --c++11 --with-python3 --without-python
get_pkg hdf5 --c++11
get_pkg protobuf --c++11 --devel
brew tap homebrew/science
get_pkgs openblas tbb lmdb
get_pkg opencv3 --with-opengl --with-qt5 --with-tbb --with-java --c++11 --with-python3

numpy_core_root="$(dirname "$(python3 -c 'import numpy.core; print(numpy.core.__file__)')")"
py3_root="$(python3-config --prefix)"
py3_incs="${py3_root}/Headers ${numpy_core_root}/include"
py3_libs="${py3_root}/lib ${numpy_core_root}/lib"
cv3_root="$(brew --prefix opencv3)"

#export PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:$(brew --prefix python3)/lib/pkgconfig"
py3_libname="$(python3-config --libs | perl -ne 'print $1 if /-l(python[^\s]*)(\.so|\.dylib)*/')"

cat <<EOF >> _tmp_Makefile.config
# Additional libraries and include dirs
PYTHON_LIBRARIES := boost_python3-mt boost_numpy3-mt ${py3_libname}
PYTHON_INCLUDE := ${py3_incs}
PYTHON_LIB := ${py3_libs}

INCLUDE_DIRS := ${py3_incs} $(brew --prefix)/include $(brew --prefix openblas)/include ${cv3_root}/include
LIBRARY_DIRS := ${py3_libs} $(brew --prefix)/lib $(brew --prefix openblas)/lib ${cv3_root}/lib $(brew --prefix boost-python)/lib
EOF


# Now proceed to building
mv _tmp_Makefile.config Makefile.config
rm -f _tmp_Makefile.config.bak
make all -j32
DISTRIBUTE_DIR=$PWD/install_dir make distribute
