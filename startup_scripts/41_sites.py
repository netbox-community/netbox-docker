from dcim.models import Site
from dcim.models import Region
from ruamel.yaml import YAML

with open('/opt/netbox/initializers/sites.yml', 'r') as stream:
  yaml = YAML(typ='safe')
  sites = yaml.load(stream)

  if sites is not None:
    for site_params in sites:
      if "region" in site_params:
        region = Region.objects.get(name=site_params.pop('region'))
        site_params['region'] = region


      site, created = Site.objects.get_or_create(**site_params)

      if created:
        print("Created site", site.name)
