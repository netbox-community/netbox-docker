import sys

from startup_script_utils import load_yaml
from virtualization.models import ClusterGroup

cluster_groups = load_yaml("/opt/netbox/initializers/cluster_groups.yml")

if cluster_groups is None:
    sys.exit()

for params in cluster_groups:
    cluster_group, created = ClusterGroup.objects.get_or_create(**params)

    if created:
        print("🗄️ Created Cluster Group", cluster_group.name)
