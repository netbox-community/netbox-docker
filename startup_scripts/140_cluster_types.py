from virtualization.models import ClusterType
from ruamel.yaml import YAML
from pathlib import Path
import sys

file = Path('/opt/netbox/initializers/cluster_types.yml')
if not file.is_file():
  sys.exit()

with file.open('r') as stream:
  yaml = YAML(typ='safe')
  cluster_types = yaml.load(stream)

  if cluster_types is not None:
    for params in cluster_types:
      cluster_type, created = ClusterType.objects.get_or_create(**params)

      if created:
        print("🧰 Created Cluster Type", cluster_type.name)
