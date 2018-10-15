from dcim.models import DeviceRole
from ruamel.yaml import YAML
from utilities.forms import COLOR_CHOICES

with open('/opt/netbox/initializers/device_roles.yml', 'r') as stream:
  yaml=YAML(typ='safe')
  device_roles = yaml.load(stream)

  if device_roles is not None:
    for device_role_params in device_roles:
      color = device_role_params.pop('color')

      for color_tpl in COLOR_CHOICES:
        if color in color_tpl:
          device_role_params['color'] = color_tpl[0]

      device_role, created = DeviceRole.objects.get_or_create(**device_role_params)

      if created:
        print("Created device role", device_role.name)
