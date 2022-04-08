import sys

from circuits.models import Provider
from startup_script_utils import (
    load_yaml,
    pop_custom_fields,
    set_custom_fields_values,
    split_params,
)

providers = load_yaml("/opt/netbox/initializers/providers.yml")

if providers is None:
    sys.exit()

for params in providers:
    custom_field_data = pop_custom_fields(params)

    matching_params, defaults = split_params(params)
    provider, created = Provider.objects.get_or_create(**matching_params, defaults=defaults)

    if created:
        print("📡 Created provider", provider.name)

    set_custom_fields_values(provider, custom_field_data)
