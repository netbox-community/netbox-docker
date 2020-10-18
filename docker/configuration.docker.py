from os.path import abspath, isfile
from os import scandir
import importlib.util
import sys

_CONFIG_DIR = '/etc/netbox/config/'
_MAIN_CONFIG = 'configuration'
_MODULE = 'netbox.configuration'
_loaded_configurations = []


def __getattr__(name):
  for config in _loaded_configurations:
    try:
      return getattr(config, name)
    except:
      pass
  raise AttributeError


def _filename(f):
  return f.name


def _import(module_name, path):
  spec = importlib.util.spec_from_file_location('', path)
  module = importlib.util.module_from_spec(spec)
  spec.loader.exec_module(module)
  sys.modules[module_name] = module

  _loaded_configurations.insert(0, module)

  print(f"🧬 loaded config '{path}'")


_main_config_path = abspath(f'{_CONFIG_DIR}/{_MAIN_CONFIG}.py')
if isfile(_main_config_path):
  _import(f'{_MODULE}.configuration', _main_config_path)
else:
  print(f"⚠️ Main configuration '{_main_config_path}' not found.")

with scandir(_CONFIG_DIR) as it:
  for f in sorted(it, key=_filename):
    if not f.is_file():
      continue

    if f.name.startswith('__'):
      continue

    if not f.name.endswith('.py'):
      continue

    if f.name == f'{_MAIN_CONFIG}.py':
      continue

    module_name = f"{_MODULE}.{f.name[:-len('.py')]}"

    _import(module_name, f.path)

if len(_loaded_configurations) == 0:
  print(f"‼️ No configuration files found in '{_CONFIG_DIR}'.")
  raise ImportError(f"No configuration files found in '{_CONFIG_DIR}'.")
