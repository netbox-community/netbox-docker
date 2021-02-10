import sys

from startup_script_utils import load_yaml
from tenancy.models import TenantGroup

tenant_groups = load_yaml("/opt/netbox/initializers/tenant_groups.yml")

if tenant_groups is None:
    sys.exit()

for params in tenant_groups:
    tenant_group, created = TenantGroup.objects.get_or_create(**params)

    if created:
        print("🔳 Created Tenant Group", tenant_group.name)
