import sys
from typing import List

from dcim.models import DeviceType, Manufacturer, Region
from dcim.models.device_component_templates import (
    ConsolePortTemplate,
    ConsoleServerPortTemplate,
    DeviceBayTemplate,
    FrontPortTemplate,
    InterfaceTemplate,
    PowerOutletTemplate,
    PowerPortTemplate,
    RearPortTemplate,
)
from startup_script_utils import (
    load_yaml,
    pop_custom_fields,
    set_custom_fields_values,
    split_params,
)
from tenancy.models import Tenant
from utilities.forms.utils import expand_alphanumeric_pattern


def expand_templates(params: List[dict], device_type: DeviceType) -> List[dict]:
    templateable_fields = ["name", "label", "positions", "rear_port", "rear_port_position"]

    expanded = []
    for param in params:
        param["device_type"] = device_type
        expanded_fields = {}
        has_plain_fields = False

        for field in templateable_fields:
            template_value = param.pop(f"{field}_template", None)

            if field in param:
                has_plain_fields = True
                expanded.append(param)
            elif template_value:
                expanded_fields[field] = list(expand_alphanumeric_pattern(template_value))

        if expanded_fields and has_plain_fields:
            raise ValueError(f"Mix of plain and template keys provided for {templateable_fields}")

        if not expanded_fields:
            continue

        elements = list(expanded_fields.values())
        master_len = len(elements[0])
        if not all([len(elem) == master_len for elem in elements]):
            raise ValueError(
                f"Number of elements in template fields "
                f"{list(expanded_fields.keys())} must be equal"
            )

        for idx in range(master_len):
            tmp = param.copy()
            for field, value in expanded_fields.items():
                if field in nested_assocs:
                    model, match_key = nested_assocs[field]
                    query = {match_key: value[idx], "device_type": device_type}
                    tmp[field] = model.objects.get(**query)
                else:
                    tmp[field] = value[idx]
            expanded.append(tmp)
    return expanded


device_types = load_yaml("/opt/netbox/initializers/device_types.yml")

if device_types is None:
    sys.exit()

match_params = ["manufacturer", "model", "slug"]
required_assocs = {"manufacturer": (Manufacturer, "name")}
optional_assocs = {"region": (Region, "name"), "tenant": (Tenant, "name")}
nested_assocs = {"rear_port": (RearPortTemplate, "name"), "power_port": (PowerPortTemplate, "name")}

supported_components = {
    "interfaces": (InterfaceTemplate, ["name"]),
    "console_ports": (ConsolePortTemplate, ["name"]),
    "console_server_ports": (ConsoleServerPortTemplate, ["name"]),
    "power_ports": (PowerPortTemplate, ["name"]),
    "power_outlets": (PowerOutletTemplate, ["name"]),
    "rear_ports": (RearPortTemplate, ["name"]),
    "front_ports": (FrontPortTemplate, ["name"]),
    "device_bays": (DeviceBayTemplate, ["name"]),
}

for params in device_types:
    custom_field_data = pop_custom_fields(params)
    components = [(v[0], v[1], params.pop(k, [])) for k, v in supported_components.items()]

    for assoc, details in required_assocs.items():
        model, field = details
        query = {field: params.pop(assoc)}

        params[assoc] = model.objects.get(**query)

    for assoc, details in optional_assocs.items():
        if assoc in params:
            model, field = details
            query = {field: params.pop(assoc)}

            params[assoc] = model.objects.get(**query)

    matching_params, defaults = split_params(params, match_params)
    device_type, created = DeviceType.objects.get_or_create(**matching_params, defaults=defaults)

    if created:
        print("🔡 Created device type", device_type.manufacturer, device_type.model)

    set_custom_fields_values(device_type, custom_field_data)

    for component in components:
        c_model, c_match_params, c_params = component
        c_match_params.append("device_type")

        if not c_params:
            continue

        expanded_c_params = expand_templates(c_params, device_type)

        for n_assoc, n_details in nested_assocs.items():
            n_model, n_field = n_details
            for c_param in expanded_c_params:
                if n_assoc in c_param:
                    n_query = {n_field: c_param[n_assoc], "device_type": device_type}
                    c_param[n_assoc] = n_model.objects.get(**n_query)

        for new_param in expanded_c_params:
            new_matching_params, new_defaults = split_params(new_param, c_match_params)
            new_obj, new_obj_created = c_model.objects.get_or_create(
                **new_matching_params, defaults=new_defaults
            )
            if new_obj_created:
                print(
                    f"🧷  Created {c_model._meta} {new_obj} component for device type {device_type}"
                )
