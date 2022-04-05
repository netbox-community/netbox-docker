import sys

from ipam.models import ASN, RIR
from startup_script_utils import load_yaml, split_params
from tenancy.models import Tenant

asns = load_yaml("/opt/netbox/initializers/asns.yml")

if asns is None:
    sys.exit()

match_params = ["asn", "rir"]
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

    matching_params, defaults = split_params(params, match_params)
    asn, created = ASN.objects.get_or_create(**matching_params, defaults=defaults)

    if created:
        print(f"🔡 Created ASN {asn.asn}")
