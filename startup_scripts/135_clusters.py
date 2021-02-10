import sys

from dcim.models import Site
from startup_script_utils import load_yaml, pop_custom_fields, set_custom_fields_values
from tenancy.models import Tenant
from virtualization.models import Cluster, ClusterGroup, ClusterType

clusters = load_yaml("/opt/netbox/initializers/clusters.yml")

if clusters is None:
    sys.exit()

required_assocs = {"type": (ClusterType, "name")}

optional_assocs = {
    "site": (Site, "name"),
    "group": (ClusterGroup, "name"),
    "tenant": (Tenant, "name"),
}

for params in clusters:
    custom_field_data = pop_custom_fields(params)

    for assoc, details in required_assocs.items():
        model, field = details
        query = {field: params.pop(assoc)}

        params[assoc] = model.objects.get(**query)

    for assoc, details in optional_assocs.items():
        if assoc in params:
            model, field = details
            query = {field: params.pop(assoc)}

            params[assoc] = model.objects.get(**query)

    cluster, created = Cluster.objects.get_or_create(**params)

    if created:
        set_custom_fields_values(cluster, custom_field_data)

        print("🗄️ Created cluster", cluster.name)
