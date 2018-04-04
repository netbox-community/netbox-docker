import importlib.util
import sys

try:
  spec = importlib.util.spec_from_file_location('configuration', '/etc/netbox/config/configuration.py')
  module = importlib.util.module_from_spec(spec)
  spec.loader.exec_module(module)
  sys.modules['netbox.configuration'] = module
except:
  raise ImportError('')
