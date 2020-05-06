from dcim.models import Manufacturer
from startup_script_utils import load_yaml
import sys

manufacturers = load_yaml('/opt/netbox/initializers/manufacturers.yml')

if not manufacturers is None:

  for params in manufacturers:
    manufacturer, created = Manufacturer.objects.get_or_create(**params)

    if created:
      print("🏭 Created Manufacturer", manufacturer.name)
