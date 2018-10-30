from dcim.models import Manufacturer
from ruamel.yaml import YAML

with open('/opt/netbox/initializers/manufacturers.yml', 'r') as stream:
  yaml = YAML(typ='safe')
  manufacturers = yaml.load(stream)

  if manufacturers is not None:
    for params in manufacturers:
      manufacturer, created = Manufacturer.objects.get_or_create(**params)

      if created:
        print("🏭 Created Manufacturer", manufacturer.name)

