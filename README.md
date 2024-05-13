# Jupyter Bootstrap

Create a virtual environment in the current directory and create a Jupyter-lab kernel for that venv. Optionally setup [Jupytext](https://jupytext.readthedocs.io/en/latest/) to automatically convert Jupyter Lab `.ipynb` files into flat python `.py` files.

## Quick Start

### Add `jupyter_bootstrap` as submodule

Adding `jupyter_bootstrap` as a git submodule make it easy to update to the latest version of the script with `git pull`. 

### Bootstrap a virtual environment

After installing the `jupyter_bootstrap` repo run the following command to build a virtual environment and add a jupyter kernel and add the [Jupytext](https://jupytext.readthedocs.io/en/latest/) module to the system python environment.

`./jupyter_bootstrap/project_init.sh -j -t`

## Usage

```text
  Create a development environment for this project

  usage:
  $ ./project_init.sh [option]

  options:
  -c: create the virtual environment
  -j: create the virtual environment and add jupyter kernel
  -t: install Jupytext and add configuration file for converting .ipynb to .py
  -p: purge the virtual environment and clean up kernel specs
  --info: virtual environment information
  -h: This help screen
```