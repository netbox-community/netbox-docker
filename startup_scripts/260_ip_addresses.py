from ipam.models import IPAddress, VRF
from dcim.models import Device, Interface
from virtualization.models import VirtualMachine
from tenancy.models import Tenant
from extras.models import CustomField, CustomFieldValue

from netaddr import IPNetwork
from startup_script_utils import load_yaml
import sys

ip_addresses = load_yaml('/opt/netbox/initializers/ip_addresses.yml')

if ip_addresses is None:
  sys.exit()

optional_assocs = {
  'tenant': (Tenant, 'name'),
  'vrf': (VRF, 'name'),
  'interface': (Interface, 'name')
}

for params in ip_addresses:
  vm = params.pop('virtual_machine', None)
  device = params.pop('device', None)
  custom_fields = params.pop('custom_fields', None)
  params['address'] = IPNetwork(params['address'])

  if vm and device:
    print("IP Address can only specify one of the following: virtual_machine or device.")
    sys.exit()

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
