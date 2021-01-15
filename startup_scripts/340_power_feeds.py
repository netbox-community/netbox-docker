import sys

from dcim.models import Rack, PowerPanel, PowerFeed, Site
from startup_script_utils import *
from tenancy.models import Tenant

power_feeds = load_yaml('/opt/netbox/initializers/power_feeds.yml')

if power_feeds is None:
  sys.exit()

required_assocs = {
  'power_panel': (PowerPanel, 'name'),
  'site': (Site, 'name')
}

optional_assocs = {
  'rack': (Rack, 'name')
}

for params in power_feeds:
  custom_field_data = pop_custom_fields(params)

  for assoc, details in required_assocs.items():
    model, field = details
    query = { field: params.pop(assoc) }

    params[assoc] = model.objects.get(**query)

  for assoc, details in optional_assocs.items():
    if assoc in params:
      model, field = details
      query = { field: params.pop(assoc) }

      params[assoc] = model.objects.get(**query)

  power_feed, created = PowerFeed.objects.get_or_create(**params)

  if created:
    set_custom_fields_values(power_feed, custom_field_data)

    print("⚡ Created Power Feed", power_feed.name)
