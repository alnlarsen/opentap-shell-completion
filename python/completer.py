import sys
from os.path import exists
import json
import subprocess
import os


shell=None
line=[]
tapdir=""
current=0
WORD_OFFSET=2

def print_zsh(jobj):
    offset = current - WORD_OFFSET
    word = line[offset] if offset >= 0 and len(line) > offset else None

    if word is not None and word.startswith("-"):
        word = word.strip("-")
        for flag in jobj["FlagCompletions"]:
            if flag["ShortName"] == word or flag["LongName"] == word:
                if flag['Type'] == 'System.Boolean': break
                suggestions = flag["SuggestedCompletions"]
                if suggestions is not None:
                    for suggestion in suggestions:
                        if suggestion is not None:
                            print(suggestion)
                return


    for comp in jobj["Completions"]:
        n = comp["Name"]
        d = comp["Description"]
        if d is None:
            print(n)
        else:
            print(f"{n}:{d}")
 
    flags = jobj["FlagCompletions"]
    if flags is None or len(flags) == 0:
        return
    types = [t['Type'].split('.')[-1] for t in flags]
    longest = len(max(types, key = len)) + 1

    for flag in flags:
        desc = flag["Description"]
        if desc is None:
            desc=""
        else:
            desc = desc.replace("\n", " ")
        typestr = flag['Type'].split('.')[-1]
        typestr = typestr + (longest - len(typestr)) * ' ' + ' -- '
        desc = f'{typestr}{desc}'
        # desc = quote(desc)
        sn = flag["ShortName"]
        if sn and len(sn) > 0:
            print(f"-{sn}:{desc}")
        ln = flag["LongName"]
        if ln and len(ln) > 0:
            print(f"--{ln}:{desc}")


def print_bash(jobj):
    pass

handlers = {}
handlers["zsh"] = print_zsh
handlers["bash"] = print_bash


def parse(args):
    jobj = None
    path = os.path.join(tapdir, ".tap-completions.json")

    if not exists(path):
        subprocess.call([os.path.join(tapdir, 'tap'), "completion", "regenerate"])
        
    if exists(path):
        with open(path, "r") as f:
            jobj = json.loads(f.read())

    # Here we keep track of which word we are currently completing.
    # This is important when candidates have common prefixes:
    # Example: tap tui, tap tui-pm, and tap tui-result.
    # This ensures that we can still correct tui to tui-pm by moving the cursor back.
    i = 0
    if jobj:
        for a in args:
            i += 1
            if i >= current:
                break

            sub = jobj["Completions"]
            for comp in sub:
                if comp["Name"] == a:
                    jobj = comp 
                    break

    if jobj and handlers[shell]:
        handlers[shell](jobj)

if __name__ == "__main__":
    # the directory of the current tap installation
    tapdir = sys.argv[1]
    # the shell which the completions should be formatted for
    shell = sys.argv[2]
    # the current word# being completed
    # subtract 1 since 'tap' is not included
    current = int(sys.argv[3])
    # the current words
    args = sys.argv[4:]
    line = args
    parse(args)

