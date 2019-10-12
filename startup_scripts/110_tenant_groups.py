from tenancy.models import TenantGroup
from ruamel.yaml import YAML
from pathlib import Path
import sys

file = Path('/opt/netbox/initializers/tenant_groups.yml')
if not file.is_file():
  sys.exit()

with file.open('r') as stream:
  yaml = YAML(typ='safe')
  tenant_groups = yaml.load(stream)

  if tenant_groups is not None:
    for params in tenant_groups:
      tenant_group, created = TenantGroup.objects.get_or_create(**params)

      if created:
        print("🔳 Created Tenant Group", tenant_group.name)
