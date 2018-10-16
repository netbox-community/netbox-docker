from dcim.models import Site, Rack, DeviceRole, DeviceType, Device, Platform
from dcim.constants import RACK_FACE_CHOICES
from ipam.models import IPAddress
from virtualization.models import Cluster
from tenancy.models import Tenant
from extras.models import CustomField, CustomFieldValue
from ruamel.yaml import YAML

with open('/opt/netbox/initializers/devices.yml', 'r') as stream:
  yaml = YAML(typ='safe')
  devices = yaml.load(stream)

  required_assocs = {
    'device_role': (DeviceRole, 'name'),
    'device_type': (DeviceType, 'model'),
    'site': (Site, 'name')
  }

  optional_assocs = {
    'tenant': (Tenant, 'name'),
    'platform': (Platform, 'name'),
    'rack': (Rack, 'name'),
    'cluster': (Cluster, 'name'),
    'primary_ip4': (IPAddress, 'address')
    'primary_ip6': (IPAddress, 'address')
  }

  if devices is not None:
    for params in devices:
      custom_fields = params.pop('custom_fields', None)

      for assoc, details in required.items():
        model, field = details
        query = dict(field=params.pop(assoc))

        params[assoc] = model.objects.get(**query)

      for assoc, details in optional_assocs.items():
        if assoc in params:
          model, field = details
          query = dict(field=params.pop(assoc))

          params[assoc] = model.objects.get(**query)

      if 'face' in params:
        for rack_face in RACK_FACE_CHOICES:
          if params['face'] in rack_face:
            params['face'] = rack_face[0]

      device, created = Device.objects.get_or_create(**params)

      if created:
        if custom_fields is not None:
          for cf_name, cf_value in custom_fields.items():
            custom_field = CustomField.objects.get(name=cf_name)
            custom_field_value = CustomFieldValue.objects.create(
              field=custom_field,
              obj=device_type,
              value=cf_value
            )

            device.custom_field_values.add(custom_field_value)

        print("Created device", device.name)
