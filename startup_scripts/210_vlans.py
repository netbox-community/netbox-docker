from dcim.models import Site
from ipam.models import VLAN, VLANGroup, Role
from tenancy.models import Tenant, TenantGroup
from extras.models import CustomField, CustomFieldValue
from startup_script_utils import load_yaml
import sys

vlans = load_yaml('/opt/netbox/initializers/vlans.yml')

if vlans is None:
  sys.exit()

optional_assocs = {
  'site': (Site, 'name'),
  'tenant': (Tenant, 'name'),
  'tenant_group': (TenantGroup, 'name'),
  'group': (VLANGroup, 'name'),
  'role': (Role, 'name')
}

for params in vlans:
  custom_fields = params.pop('custom_fields', None)

  for assoc, details in optional_assocs.items():
    if assoc in params:
      model, field = details
      query = { field: params.pop(assoc) }

      params[assoc] = model.objects.get(**query)

  vlan, created = VLAN.objects.get_or_create(**params)

  if created:
    if custom_fields is not None:
      for cf_name, cf_value in custom_fields.items():
        custom_field = CustomField.objects.get(name=cf_name)
        custom_field_value = CustomFieldValue.objects.create(
          field=custom_field,
          obj=vlan,
          value=cf_value
        )

        vlan.custom_field_values.add(custom_field_value)

    print("🏠 Created VLAN", vlan.name)
