#!/bin/bash

source ./tap-completion.bash


COMP_CWORD=2
_tap_complete_fn tap package list --architecture x

_buildQuery package list hello wowoow
