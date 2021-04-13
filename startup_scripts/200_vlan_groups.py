import sys

from django.contrib.contenttypes.models import ContentType
from ipam.models import VLANGroup
from startup_script_utils import load_yaml, pop_custom_fields, set_custom_fields_values

vlan_groups = load_yaml("/opt/netbox/initializers/vlan_groups.yml")

if vlan_groups is None:
    sys.exit()

optional_assocs = {"scope": (None, "name")}

for params in vlan_groups:
    custom_field_data = pop_custom_fields(params)

    for assoc, details in optional_assocs.items():
        if assoc in params:
            model, field = details
            query = {field: params.pop(assoc)}
            # Get model from Contenttype
            scope_type = params.pop("scope_type", None)
            if not scope_type:
                print(f"VLAN Group '{params['name']}': scope_type is missing from VLAN Group")
                continue
            app_label, model = str(scope_type).split(".")
            ct = ContentType.objects.filter(app_label=app_label, model=model).first()
            if not ct:
                print(
                    f"VLAN Group '{params['name']}': ContentType for "
                    + f"app_label = '{app_label}' and model = '{model}' not found"
                )
                continue
            params["scope_id"] = ct.model_class().objects.get(**query).id
    vlan_group, created = VLANGroup.objects.get_or_create(**params)

    if created:
        set_custom_fields_values(vlan_group, custom_field_data)

        print("🏘️ Created VLAN Group", vlan_group.name)
