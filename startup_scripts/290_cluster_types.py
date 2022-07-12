import sys

from startup_script_utils import load_yaml, split_params
from virtualization.models import ClusterType

cluster_types = load_yaml("/opt/netbox/initializers/cluster_types.yml")

if cluster_types is None:
    sys.exit()

for params in cluster_types:
    matching_params, defaults = split_params(params)
    cluster_type, created = ClusterType.objects.get_or_create(**matching_params, defaults=defaults)

    if created:
        print("🧰 Created Cluster Type", cluster_type.name)
