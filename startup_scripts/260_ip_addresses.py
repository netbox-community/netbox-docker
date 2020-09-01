import sys

from dcim.models import Device, Interface
from django.contrib.contenttypes.models import ContentType
from django.db.models import Q
from extras.models import CustomField, CustomFieldValue
from ipam.models import VRF, IPAddress
from netaddr import IPNetwork
from startup_script_utils import load_yaml
from tenancy.models import Tenant
from virtualization.models import VirtualMachine, VMInterface

ip_addresses = load_yaml('/opt/netbox/initializers/ip_addresses.yml')

if ip_addresses is None:
  sys.exit()

optional_assocs = {
  'tenant': (Tenant, 'name'),
  'vrf': (VRF, 'name'),
  'interface': (None, None)
}

vm_interface_ct = ContentType.objects.filter(Q(app_label='virtualization', model='vminterface')).first()
interface_ct = ContentType.objects.filter(Q(app_label='dcim', model='interface')).first()

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
              query = { 'name': params.pop(assoc), "virtual_machine_id": vm_id }
              params['assigned_object_type'] = vm_interface_ct
              params['assigned_object_id'] = VMInterface.objects.get(**query).id
          elif device:
              dev_id = Device.objects.get(name=device).id
              query = { 'name': params.pop(assoc), "device_id": dev_id }
              params['assigned_object_type'] = interface_ct
              params['assigned_object_id'] = Interface.objects.get(**query).id
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
