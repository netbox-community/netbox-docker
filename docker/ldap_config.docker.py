import importlib.util
import sys

try:
  spec = importlib.util.spec_from_file_location('ldap_config', '/etc/netbox/ldap_config.py')
  module = importlib.util.module_from_spec(spec)
  spec.loader.exec_module(module)
  sys.modules['netbox.ldap_config'] = module
except:
  raise ImportError('')
