from dcim.models import Site
from ipam.models import VLAN, VLANGroup, Role
from ipam.constants import VLAN_STATUS_CHOICES
from tenancy.models import Tenant, TenantGroup
from extras.models import CustomField, CustomFieldValue
from ruamel.yaml import YAML

from pathlib import Path
import sys

file = Path('/opt/netbox/initializers/vlans.yml')
if not file.is_file():
  sys.exit()

with file.open('r') as stream:
  yaml = YAML(typ='safe')
  vlans = yaml.load(stream)

  optional_assocs = {
    'site': (Site, 'name'),
    'tenant': (Tenant, 'name'),
    'tenant_group': (TenantGroup, 'name'),
    'group': (VLANGroup, 'name'),
    'role': (Role, 'name')
  }

  if vlans is not None:
    for params in vlans:
      custom_fields = params.pop('custom_fields', None)

      for assoc, details in optional_assocs.items():
        if assoc in params:
          model, field = details
          query = { field: params.pop(assoc) }

          params[assoc] = model.objects.get(**query)

      if 'status' in params:
        for vlan_status in VLAN_STATUS_CHOICES:
          if params['status'] in vlan_status:
            params['status'] = vlan_status[0]
            break

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
