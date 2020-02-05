from dcim.models import Site
from virtualization.models import Cluster, ClusterType, ClusterGroup
from extras.models import CustomField, CustomFieldValue
from startup_script_utils import load_yaml
import sys

clusters = load_yaml('/opt/netbox/initializers/clusters.yml')

if clusters is None:
  sys.exit()

required_assocs = {
  'type': (ClusterType, 'name')
}

optional_assocs = {
  'site': (Site, 'name'),
  'group': (ClusterGroup, 'name')
}

for params in clusters:
  custom_fields = params.pop('custom_fields', None)

  for assoc, details in required_assocs.items():
    model, field = details
    query = { field: params.pop(assoc) }

    params[assoc] = model.objects.get(**query)

  for assoc, details in optional_assocs.items():
    if assoc in params:
      model, field = details
      query = { field: params.pop(assoc) }

      params[assoc] = model.objects.get(**query)

  cluster, created = Cluster.objects.get_or_create(**params)

  if created:
    if custom_fields is not None:
      for cf_name, cf_value in custom_fields.items():
        custom_field = CustomField.objects.get(name=cf_name)
        custom_field_value = CustomFieldValue.objects.create(
          field=custom_field,
          obj=cluster,
          value=cf_value
        )

        cluster.custom_field_values.add(custom_field_value)

    print("🗄️ Created cluster", cluster.name)
