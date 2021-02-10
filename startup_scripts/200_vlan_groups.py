import sys

from dcim.models import Site
from ipam.models import VLANGroup
from startup_script_utils import load_yaml, pop_custom_fields, set_custom_fields_values

vlan_groups = load_yaml("/opt/netbox/initializers/vlan_groups.yml")

if vlan_groups is None:
    sys.exit()

optional_assocs = {"site": (Site, "name")}

for params in vlan_groups:
    custom_field_data = pop_custom_fields(params)

    for assoc, details in optional_assocs.items():
        if assoc in params:
            model, field = details
            query = {field: params.pop(assoc)}

            params[assoc] = model.objects.get(**query)

    vlan_group, created = VLANGroup.objects.get_or_create(**params)

    if created:
        set_custom_fields_values(vlan_group, custom_field_data)

        print("🏘️ Created VLAN Group", vlan_group.name)
