#!/bin/bash
#
# Copyright (c) 2022, National Technology & Engineering Solutions of Sandia,
# LLC (NTESS). Under the terms of Contract DE-NA0003525 with NTESS, the U.S.
# Government retains certain rights in this software.
#
# This software is released under the BSD 3-clause license. See LICENSE file
# for more details.
#
#
function install_spack_manager(){
  git clone --branch develop https://github.com/sandialabs/spack-manager $SPACK_ROOT/../spack-manager
  spack config --scope site add "config:extensions:[${SPACK_MANAGER}/spack-manager]"
  spack manager add ${SPACK_MANAGER}
}

if ! $(type '_spack_start_called' 2>/dev/null | grep -q 'function'); then
  export SPACK_ROOT=${SPACK_MANAGER}/spack
  export SPACK_USER_CACHE_PATH=${SPACK_MANAGER}/.cache
  export SPACK_USER_CONFIG_PATH=${SPACK_MANAGER}/.spack
  source ${SPACK_ROOT}/share/spack/setup-env.sh

  # Clean Spack misc caches
  # Put this back in if outdated caches directory still causes problems when updating Spack submodule
  #spack clean -m
  
  # move the bootstrap store outside the user config path
  if [[ -z $(spack config blame bootstrap | grep "root: ${SPACK_MANAGER}/.bootstrap") ]]; then
    spack bootstrap root ${SPACK_MANAGER}/.bootstrap
  fi

  if [[ -z $(spack config --scope site blame config | grep "environments_root: ${SPACK_MANAGER}/environments") ]]; then
    spack config --scope site add config:environments_root:${SPACK_MANAGER}/environments
  fi

  if [[ -z $(spack config --scope site blame config | grep spack-manager) ]]; then
    install_spack_manager
  fi

  if [[ -z $(spack config --scope site blame concretizer | grep 'unify:false') ]]; then
    spack config --scope site add "concretizer:unify:false"
  fi

  if [[ -z $(spack repo list | awk '{print $1" "$2}' | grep "exawind $SPACK_MANAGER") ]]; then
    spack repo add ${SPACK_MANAGER}/repos/exawind
  fi
  
  if [[ -z $(spack config --scope site blame bootstrap | grep spack-bootstrap-store) ]]; then
    if [[ "${SPACK_MANAGER_MACHINE}" == "cee" ]]; then
      spack bootstrap add --scope site --trust wind-binaries /projects/wind/spack-bootstrap-store/metadata/binaries
    fi
  fi

  source ${SPACK_MANAGER}/spack-manager/scripts/quick_commands.sh
  export PATH=${PATH}:${SPACK_MANAGER}/scripts
  # needed for package imports
  export PYTHONPATH=${PYTHONPATH}:${SPACK_MANAGER}
  # define a function since environment variables are sometimes preserved in a subshell but functions aren't
  # see https://github.com/psakievich/spack-manager/issues/210
  function _spack_start_called(){
    echo "TRUE"
  }
fi
