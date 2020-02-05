from tenancy.models import TenantGroup
from startup_script_utils import load_yaml
import sys

tenant_groups = load_yaml('/opt/netbox/initializers/tenant_groups.yml')

if tenant_groups is None:
  sys.exit()

for params in tenant_groups:
  tenant_group, created = TenantGroup.objects.get_or_create(**params)

  if created:
    print("🔳 Created Tenant Group", tenant_group.name)
