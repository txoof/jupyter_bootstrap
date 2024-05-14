#!/usr/bin/env bash

# create a virtual environment for a project and install the dependencies

VERSION='0.1.1'
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
PROJECT_DIR=$(dirname $SCRIPT_DIR)
PROJECT_NAME=$(basename $PROJECT_DIR)
ACTIVATE_SYMLINK="venv_activate"
OS=$(uname -s)
JUPYTEXT_CFG=$(cat <<'EOF'
formats = "ipynb,py:light"
EOF
)
JUPYTEXT_TOML='./jupytext.toml'

case $OS in
    Linux)
        OS="linux"
        ;;
    Darwin)
        OS="darwin"
        ;;
    *)
        OS="unknown"
        ;;
esac

if [ $OS == "linux" ]; then
    MD5="md5sum"
    IPADDRESS=$(hostname -I | cut -d " " -f 1)
elif [ $OS == "darwin" ]; then
    MD5="md5"
    IPADDRESS=$(ifconfig en0 | awk '/inet / {print $2}')
else
    abort "Unsupported OS: $OS"
fi


# get the currently installed python version
# get the currently installed python version
PY_VERSION=$(python3 -c 'import sys; print("{}.{}".format(sys.version_info.major, sys.version_info.minor))')
PY_MAJOR=$(echo "$PY_VERSION" | cut -d. -f1)
PY_MINOR=$(echo "$PY_VERSION" | cut -d. -f2)

# virtual environment name

VENV_HASH=$(echo -n "$PROJECT_DIR" | $MD5 | cut -c1-5)
VENV=$PROJECT_DIR/$PROJECT_NAME-VENV-$VENV_HASH

function abort {
  # abort installation with message
  printf "%s\n" "$@"
  printf "%s\n\nThis installer can be resumed with:\n"
  printf "sudo $SCRIPT_DIR/$(basename "$0")\n"
  exit 1
}

function Help {
  echo "
  jupyter_bootstrap project_init.sh 
  v$VERSION

  Create a development environment for this project

  usage:
  $ $0 [options]

  options:
  -c: create the virtual environment
  -j: create the virtual environment and add jupyter kernel
  -t: install jupytext and add configuration file for converting .ipynb to .py
  -p: purge the virtual environment and clean up kernel specs
  -r [filename]: optional alternative requirements file to process
  -i: virtual environment information
  -f: force creation of virtual environment even if it exists
  -v: version information
  -h: This help screen


"
exit 0
}


function venv_info {
  if [ ! -d $VENV ]
  then
    echo "No virtual environment exists for this project.
Create a virtual environment with:
  $0 -c|-j

For more information:
  $0 -h
    "
    exit 0
  fi

  echo "Virtual environtment information
  * Path: $VENV
  * Activate virtual env: 
    $ source $PROJECT_DIR/utilities/venv_activate

"

  if python3 -m pip show "jupyterlab" > /dev/null; then
    echo "Jupyter Information:
  * Launch Jupyter Notebook locally: 
    $ cd ~; jupyter lab

  * Launch Jupyter Notebook for access on the local network:
    $ cd ~; jupyter lab --ip=$IPADDRESS --no-browser

"
  fi
}



function create_venv {
    venvName=$(basename $VENV)

    if [ $INSTALL -gt 0 ]; then
        echo "Creating virtual environment $venvName"
        if [ -d "$VENV" ] && [ "$FORCE" -lt 1 ]; then
            echo "venv already exists at $venvName; skipping creation"
        else
            python3 -m venv $VENV
            source $VENV/bin/activate
            pip install --upgrade pip
            echo "Installing requirements"
            if [ -f $PROJECT_DIR/$REQUIREMENTS ]; then
                pip install -r $PROJECT_DIR/$REQUIREMENTS 
            else
                echo "$REQUIREMENTS file not found in $PROJECT_DIR"
            fi
            deactivate

            # create a symlink to the activate file
            # check if symlink exists
            if [ -L $PROJECT_DIR/venv_activate ]; then
                echo ""
            else
                echo "creating venv_activate symlink"
                ln -s $VENV/bin/activate $ACTIVATE_SYMLINK
                if grep -Fxq "$ACTIVATE_SYMLINK" $PROJECT_DIR/.gitignore
                then
                    echo "venv_activate already in .gitignore"
                else
                    echo "adding venv_activate to .gitignore"
                    echo "$ACTIVATE_SYMLINK" >> $PROJECT_DIR/.gitignore
                fi

            fi
        fi


        # add venv to .gitignore
        if grep -Fxq "$venvName/*" $PROJECT_DIR/.gitignore
        then
            echo "venv already in .gitignore"
        else
            echo "adding virtualenv to .gitignore"
            echo "$venvName/*" >> $PROJECT_DIR/.gitignore
        fi
    fi

    if [[ $JUPYTER -gt 0 && $INSTALL -gt 0 ]]; then
        echo "installing jupyter kernel for $venvName"
        if python -m ipykernel --version > /dev/null 2>&1; then
            python -m ipykernel install --user --name=$venvName
        
        else
            echo "Jupyter (lab) is not installed in the current system environment."
            echo "try `pip install jupyterlab`"
            echo "" 
            abort "Please install jupyterlab"         
        fi
    fi

    if [ $PURGE -gt 0 ]
    then
        echo "Purging kernelspec $venvName"
        jupyter kernelspec remove $venvName $venvName
        echo "Removing $VENV"
        rm -rf $VENV
    fi
}


# install jupytext python module
function install_jupytext {
    if [[ $JUPYTEXT -eq 0 ]]; then
        return
    fi
    if python3 -m pip show "jupytext" > /dev/null; then
        echo "jupytext already installed"
    else
        echo "installing jupytext"
        pip install jupytext
    fi
    echo "creating jupytext configuration file"
    echo "$JUPYTEXT_CFG" > $JUPYTEXT_TOML
}

## main program ##
INSTALL=0
PURGE=0
JUPYTER=0
JUPYTEXT=0
FORCE=0
REQUIREMENTS='requirements.txt'

while getopts ":hcfjptivr:" opt; do
  case ${opt} in
    h )
      Help
      ;;
    c )
      INSTALL=1
      ;;
    f )
      FORCE=1
      ;;
    j )
      JUPYTER=1
      INSTALL=1
      ;;
    t )
      JUPYTEXT=1
      ;;
    p )
      PURGE=1
      INSTALL=0
      ;;
    r )
      REQUIREMENTS=$OPTARG
      ;;
    i )
      venv_info
      exit 0
      ;;
    v )
      echo "$0 v$VERSION"
      exit 0
      ;;
    \? )
      echo "Invalid Option: -$OPTARG" 1>&2
      Help
      ;;
  esac
done

if [[ $INSTALL -eq 0 ]] && [[ $PURGE -eq 0 ]] && [[ $JUPYTEXT -eq 0 ]]; then
  Help
fi

create_venv
install_jupytext
