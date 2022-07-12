import sys

from startup_script_utils import load_yaml, split_params
from tenancy.models import TenantGroup

tenant_groups = load_yaml("/opt/netbox/initializers/tenant_groups.yml")

if tenant_groups is None:
    sys.exit()

for params in tenant_groups:
    matching_params, defaults = split_params(params)
    tenant_group, created = TenantGroup.objects.get_or_create(**matching_params, defaults=defaults)

    if created:
        print("🔳 Created Tenant Group", tenant_group.name)
