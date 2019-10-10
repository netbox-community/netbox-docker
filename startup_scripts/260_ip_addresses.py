from ipam.models import IPAddress, VRF
from dcim.models import Device, Interface
from virtualization.models import VirtualMachine
from tenancy.models import Tenant
from extras.models import CustomField, CustomFieldValue
from ruamel.yaml import YAML

from netaddr import IPNetwork
from pathlib import Path
import sys

file = Path('/opt/netbox/initializers/ip_addresses.yml')
if not file.is_file():
  sys.exit()

with file.open('r') as stream:
  yaml = YAML(typ='safe')
  ip_addresses = yaml.load(stream)

  optional_assocs = {
    'tenant': (Tenant, 'name'),
    'vrf': (VRF, 'name'),
    'interface': (Interface, 'name')
  }

  if ip_addresses is not None:
    for params in ip_addresses:
      vm = params.pop('virtual_machine', None)
      device = params.pop('device', None)
      custom_fields = params.pop('custom_fields', None)
      params['address'] = IPNetwork(params['address'])

      for assoc, details in optional_assocs.items():
        if assoc in params:
          model, field = details
          if assoc == 'interface':
              if vm:
                  vm_id = VirtualMachine.objects.get(name=vm).id
                  query = { field: params.pop(assoc), "virtual_machine_id": vm_id }
              elif device:
                  dev_id = Device.objects.get(name=device).id
                  query = { field: params.pop(assoc), "device_id": dev_id }
          else:
              query = { field: params.pop(assoc) }
          params[assoc] = model.objects.get(**query)

      ip_address, created = IPAddress.objects.get_or_create(**params)

      if created:
        if custom_fields is not None:
          for cf_name, cf_value in custom_fields.items():
            custom_field = CustomField.objects.get(name=cf_name)
            custom_field_value = CustomFieldValue.objects.create(
              field=custom_field,
              obj=ip_address,
              value=cf_value
            )

            ip_address.custom_field_values.add(custom_field_value)

        print("🧬 Created IP Address", ip_address.address)
