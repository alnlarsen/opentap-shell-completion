#!/bin/bash

. ./tap-completion.bash


COMP_WORDS=(../bin/Debug/tap completion regenerate --browsable x)
COMP_CWORD="4"

_tap_complete_fn ${COMP_WORDS[@]}

# _buildQuery package list hello wowoow
