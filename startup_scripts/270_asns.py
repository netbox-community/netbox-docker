import sys

from ipam.models import ASN, RIR
from startup_script_utils import load_yaml
from tenancy.models import Tenant

asns = load_yaml("/opt/netbox/initializers/asns.yml")

if asns is None:
    sys.exit()

required_assocs = {"rir": (RIR, "name")}

optional_assocs = {"tenant": (Tenant, "name")}

for params in asns:
    for assoc, details in required_assocs.items():
        model, field = details
        query = {field: params.pop(assoc)}

        params[assoc] = model.objects.get(**query)

    for assoc, details in optional_assocs.items():
        if assoc in params:
            model, field = details
            query = {field: params.pop(assoc)}

            params[assoc] = model.objects.get(**query)

    asn, created = ASN.objects.get_or_create(**params)

    if created:
        print(f"🔡 Created ASN {asn.asn}")
