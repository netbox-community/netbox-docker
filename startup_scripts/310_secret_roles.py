import sys
from secrets.models import SecretRole

from startup_script_utils import load_yaml

secret_roles = load_yaml("/opt/netbox/initializers/secret_roles.yml")

if secret_roles is None:
    sys.exit()

for params in secret_roles:
    secret_role, created = SecretRole.objects.get_or_create(**params)

    if created:
        print("🔑 Created Secret Role", secret_role.name)
