from dcim.models import Site
from ipam.models import Prefix, VLAN, Role, VRF
from tenancy.models import Tenant, TenantGroup
from extras.models import CustomField, CustomFieldValue
from netaddr import IPNetwork
from startup_script_utils import load_yaml
import sys

prefixes = load_yaml('/opt/netbox/initializers/prefixes.yml')

if prefixes is None:
  sys.exit()

optional_assocs = {
  'site': (Site, 'name'),
  'tenant': (Tenant, 'name'),
  'tenant_group': (TenantGroup, 'name'),
  'vlan': (VLAN, 'name'),
  'role': (Role, 'name'),
  'vrf': (VRF, 'name')
}

for params in prefixes:
  custom_fields = params.pop('custom_fields', None)
  params['prefix'] = IPNetwork(params['prefix'])

  for assoc, details in optional_assocs.items():
    if assoc in params:
      model, field = details
      query = { field: params.pop(assoc) }
      params[assoc] = model.objects.get(**query)

  prefix, created = Prefix.objects.get_or_create(**params)

  if created:
    if custom_fields is not None:
      for cf_name, cf_value in custom_fields.items():
        custom_field = CustomField.objects.get(name=cf_name)
        custom_field_value = CustomFieldValue.objects.create(
          field=custom_field,
          obj=prefix,
          value=cf_value
        )
        prefix.custom_field_values.add(custom_field_value)

    print("📌 Created Prefix", prefix.prefix)
