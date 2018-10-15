from dcim.models import RackRole
from ruamel.yaml import YAML
from utilities.forms import COLOR_CHOICES

with open('/opt/netbox/initializers/rack_roles.yml', 'r') as stream:
  yaml=YAML(typ='safe')
  rack_roles = yaml.load(stream)

  if rack_roles is not None:
    for rack_role_params in rack_roles:
      color = rack_role_params.pop('color', None)

      for color_tpl in COLOR_CHOICES:
        if color in color_tpl:
          rack_role_params['color'] = color_tpl[0]

      rack_role, created = RackRole.objects.get_or_create(**rack_role_params)

      if created:
        print("Created rack role", rack_role.name)
