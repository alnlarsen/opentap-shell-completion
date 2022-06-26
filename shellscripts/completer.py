import sys
from os.path import exists
import json
import subprocess
import os


shell=None
line=[]
tapdir=""

def print_zsh(jobj):
    words = []
    if len(line) > 0: words += [line[-1]]
    if len(line) > 1: words += [line[-2]]

    for word in words:
        if word.startswith("-"):
            word = word.strip("-")
            if len(word) == 0: break
            for flag in jobj["FlagCompletions"]:
                if flag["ShortName"] == word or flag["LongName"] == word:
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
 
    for flag in jobj["FlagCompletions"]:
        desc = flag["Description"]
        if desc is None:
            desc=""
        else:
            desc = desc.replace("\n", " ")
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

    if jobj:
        for a in args:
            sub = jobj["Completions"]
            for comp in sub:
                if comp["Name"] == a:
                    jobj = comp 
                    break

    if jobj and handlers[shell]:
        handlers[shell](jobj)

if __name__ == "__main__":
    tapdir = sys.argv[1]
    shell = sys.argv[2]
    args = sys.argv[3:]
    line = args
    parse(args)

