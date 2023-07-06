set -gx PIP_DISABLE_PIP_VERSION_CHECK 1
set -gx PIP_REQUIRE_VIRTUALENV 1
set -gx PIPX_DEFAULT_PYTHON $HOMEBREW_PREFIX/bin/python3 # don't break venv's on brew upgrade
set -gx POETRY_VIRTUALENVS_IN_PROJECT true
set -gx PYTHONDONTWRITEBYTECODE 1

# if type -q pdm
#   eval (pdm --pep582)
# end