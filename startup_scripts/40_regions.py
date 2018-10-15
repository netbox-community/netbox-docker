from dcim.models import Region
from ruamel.yaml import YAML

with open('/opt/netbox/initializers/regions.yml', 'r') as stream:
  yaml=YAML(typ='safe')
  regions = yaml.load(stream)

  if regions is not None:
    for region_params in regions:
      if "parent" in region_params:
        parent = Region.objects.get(name=region_params.pop('parent'))
        region_params['parent'] = parent

      region, created = Region.objects.get_or_create(**region_params)

      if created:
        print("Created region", region.name)
