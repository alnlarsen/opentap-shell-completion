#/usr/bin/env bash

_portable_get_real_dirname() {
  if [[ $(uname) == Darwin ]]; then
    # Mac uses BSD readlink which supports different flags

    # relativePath is empty if this is a regular file
    # Otherwise it is a relative path from the link to the real file
    foundPath="$1"
    relativePath="$(readlink "$foundPath")"
    # Keep looping until the file is resolved to a regular file
    while [[ "$relativePath" ]]; do
      # File is a link; follow it
      pushd "$(dirname "$foundPath")" >/dev/null
      pushd "$(dirname "$relativePath")" >/dev/null
      foundPath="$(pwd)/$(basename "$0")"
      popd >/dev/null
      popd >/dev/null
      relativePath="$(readlink "$foundPath")"
    done

    echo "$(dirname "$foundPath")"
  else
    # We are on linux -- Use GNU Readline normally
    echo "$(dirname "$(readlink -f "$(which "$1")")")"
  fi
}

function _jq() {
  local src="$1"
  local optimize=false
  local args=""

  if [ $optimize = false ]; then
    args=""
  else
    args="-c"
  fi
  ../native/jq-linux64 "$@"
}


_tap_complete_fn()
{
  local binary="${COMP_WORDS[0]}"
  local tapdir="`_portable_get_real_dirname "$binary"`"
  local jqPath="$tapdir/Packages/ShellCompletion/jq"
  if [ ! -x "$jqPath" ]; then 
    # We cannot do anything if jq is not installed. We cannot even give an error.
    # This is probably happening because the plugin is not installed.
    return;
  fi

  for word in "${COMP_WORDS[@]}"; do
    echo $word
  done
}

function _tap_completions()
{
  COMPREPLY+=(_jq .Completions[].Name ./.tap-completions.json)
}

complete -F _tap_completions tap

