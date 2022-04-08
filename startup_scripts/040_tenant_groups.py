import sys

from startup_script_utils import load_yaml
from tenancy.models import TenantGroup

tenant_groups = load_yaml("/opt/netbox/initializers/tenant_groups.yml")

if tenant_groups is None:
    sys.exit()

optional_assocs = {
    'parent': (TenantGroup, "name"),
}

for params in tenant_groups:
    for assoc, details in optional_assocs.items():
        if assoc in params:
            model, field = details
            query = {field: params.pop(assoc)}
            params[assoc] = model.objects.get(**query)

    tenant_group, created = TenantGroup.objects.get_or_create(**params)

    if created:
        print("🔳 Created Tenant Group", tenant_group.name)
