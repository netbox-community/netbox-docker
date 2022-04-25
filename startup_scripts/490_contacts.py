import sys

from startup_script_utils import (
    load_yaml,
    pop_custom_fields,
    set_custom_fields_values,
    split_params,
)
from tenancy.models import Contact, ContactGroup

contacts = load_yaml("/opt/netbox/initializers/contacts.yml")

if contacts is None:
    sys.exit()

optional_assocs = {"group": (ContactGroup, "name")}

for params in contacts:
    custom_field_data = pop_custom_fields(params)

    for assoc, details in optional_assocs.items():
        if assoc in params:
            model, field = details
            query = {field: params.pop(assoc)}

            params[assoc] = model.objects.get(**query)

    matching_params, defaults = split_params(params)
    contact, created = Contact.objects.get_or_create(**matching_params, defaults=defaults)

    if created:
        print("👩‍💻 Created Contact", contact.name)

    set_custom_fields_values(contact, custom_field_data)
