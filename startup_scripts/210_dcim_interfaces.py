import sys

from dcim.models import Device, Interface
from startup_script_utils import (
    load_yaml,
    pop_custom_fields,
    set_custom_fields_values,
    split_params,
)

interfaces = load_yaml("/opt/netbox/initializers/dcim_interfaces.yml")

if interfaces is None:
    sys.exit()

match_params = ["device", "name"]
required_assocs = {"device": (Device, "name")}
related_assocs = {
    "bridge": (Interface, "name"),
    "lag": (Interface, "name"),
    "parent": (Interface, "name"),
}

for params in interfaces:
    custom_field_data = pop_custom_fields(params)

    related_interfaces = {k: params.pop(k, None) for k in related_assocs}

    for assoc, details in required_assocs.items():
        model, field = details
        query = {field: params.pop(assoc)}

        params[assoc] = model.objects.get(**query)

    matching_params, defaults = split_params(params, match_params)
    interface, created = Interface.objects.get_or_create(**matching_params, defaults=defaults)

    if created:
        print(f"🧷 Created interface {interface} on {interface.device}")

    set_custom_fields_values(interface, custom_field_data)

    for related_field, related_value in related_interfaces.items():
        if not related_value:
            continue

        r_model, r_field = related_assocs[related_field]

        if related_field == "parent" and not interface.parent_id:
            query = {r_field: related_value, "device": interface.device}
            try:
                related_obj = r_model.objects.get(**query)
            except Interface.DoesNotExist:
                print(f"⚠️ Could not find parent interface with: {query} for interface {interface}")
                raise

            interface.parent_id = related_obj.id
            interface.save()
            print(
                f"🧷 Attached interface {interface} on {interface.device} "
                f"to parent {related_obj}"
            )
        else:
            query = {r_field: related_value, "device": interface.device, "type": related_field}
            related_obj, rel_obj_created = r_model.objects.get_or_create(**query)

            if rel_obj_created:
                setattr(interface, f"{related_field}_id", related_obj.id)
                interface.save()
                print(f"🧷 Created {related_field} interface {interface} on {interface.device}")
