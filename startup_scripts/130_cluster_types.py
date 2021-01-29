from virtualization.models import ClusterType
from startup_script_utils import load_yaml
import sys

cluster_types = load_yaml('/opt/netbox/initializers/cluster_types.yml')

if cluster_types is None:
  sys.exit()

for params in cluster_types:
  cluster_type, created = ClusterType.objects.get_or_create(**params)

  if created:
    print("🧰 Created Cluster Type", cluster_type.name)
