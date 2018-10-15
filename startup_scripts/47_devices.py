from dcim.models import Site, Rack, DeviceRole, DeviceType, Device, Platform
from dcim.constants import RACK_FACE_CHOICES
from ipam.models import IPAddress
from tenancy.models import Tenant
from extras.models import CustomField, CustomFieldValue
from ruamel.yaml import YAML

with open('/opt/netbox/initializers/devices.yml', 'r') as stream:
  yaml = YAML(typ='safe')
  devices = yaml.load(stream)

  optional_assocs = {
    'platform': Platform,
    'tenant': Tenant
    'rack': Rack
    'primary_ip4': IPAddress
    'primary_ip6': IPAddress
  }

  if devices is not None:
    for device_params in devices:
      custom_fields = device_params.pop('custom_fields', None)

      device_params['device_role'] = DeviceRole.objects.get(name=device_params.pop('device_role'))
      device_params['device_type'] = DeviceType.objects.get(model=device_params.pop('device_type'))
      device_params['site'] = Site.objects.get(name=device_params.pop('site'))

      for param_name, model in optional_assoc.items():
        if param_name in device_params:
          device_params[param_name] = model.objects.get(name=device_params.pop(param_name))

      for rack_face in RACK_FACE_CHOICES:
        if device_params['face'] in rack_face:
          device_params['face'] = rack_face[0]

      device, created = Device.objects.get_or_create(**device_params)

      if created:
        if custom_fields is not None:
          for cf_name, cf_value in custom_fields.items():
            custom_field = CustomField.objects.get(name=cf_name)
            custom_field_value = CustomFieldValue.objects.create(field=custom_field, obj=device, value=cf_value)

            device.custom_field_values.add(custom_field_value)

        print("Created device", device.name)
