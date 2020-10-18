from dcim.models import Site, Rack, DeviceRole, DeviceType, Device, Platform
from virtualization.models import Cluster
from tenancy.models import Tenant
from extras.models import CustomField, CustomFieldValue
from startup_script_utils import load_yaml
import sys

devices = load_yaml('/opt/netbox/initializers/devices.yml')

if devices is None:
  sys.exit()

required_assocs = {
  'device_role': (DeviceRole, 'name'),
  'device_type': (DeviceType, 'model'),
  'site': (Site, 'name')
}

optional_assocs = {
  'tenant': (Tenant, 'name'),
  'platform': (Platform, 'name'),
  'rack': (Rack, 'name'),
  'cluster': (Cluster, 'name')
}

for params in devices:
  custom_fields = params.pop('custom_fields', None)
  # primary ips are handled later in `270_primary_ips.py`
  params.pop('primary_ip4', None)
  params.pop('primary_ip6', None)

  for assoc, details in required_assocs.items():
    model, field = details
    query = { field: params.pop(assoc) }

    params[assoc] = model.objects.get(**query)

  for assoc, details in optional_assocs.items():
    if assoc in params:
      model, field = details
      query = { field: params.pop(assoc) }

      params[assoc] = model.objects.get(**query)

  device, created = Device.objects.get_or_create(**params)

  if created:
    if custom_fields is not None:
      for cf_name, cf_value in custom_fields.items():
        custom_field = CustomField.objects.get(name=cf_name)
        custom_field_value = CustomFieldValue.objects.create(
          field=custom_field,
          obj=device,
          value=cf_value
        )

        device.custom_field_values.add(custom_field_value)

    print("🖥️  Created device", device.name)
