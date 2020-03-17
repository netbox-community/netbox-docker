#!/usr/bin/env python3

import runpy
from os import scandir
from os.path import dirname, abspath

this_dir = dirname(abspath(__file__))

def filename(f):
  return f.name

with scandir(dirname(abspath(__file__))) as it:
  for f in sorted(it, key = filename):
    if f.name.startswith('__') or not f.is_file():
      continue
      
    print(f"Running {f.path}")
    runpy.run_path(f.path)
