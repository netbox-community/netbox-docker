from dcim.models import Manufacturer
from ruamel.yaml import YAML

with open('/opt/netbox/initializers/manufacturers.yml', 'r') as stream:
  yaml = YAML(typ='safe')
  manufacturers = yaml.load(stream)

  if manufacturers is not None:
    for manufacturer_params in manufacturers:
      manufacturer, created = Manufacturer.objects.get_or_create(**manufacturer_params)

      if created:
          print("Created Manufacturer", manufacturer.name)

