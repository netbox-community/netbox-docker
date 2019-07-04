from dcim.models import Site
from virtualization.models import Cluster, ClusterType, ClusterGroup
from extras.models import CustomField, CustomFieldValue
from ruamel.yaml import YAML

from pathlib import Path
import sys

file = Path('/opt/netbox/initializers/clusters.yml')
if not file.is_file():
  sys.exit()

with file.open('r') as stream:
  yaml = YAML(typ='safe')
  clusters = yaml.load(stream)

  required_assocs = {
    'type': (ClusterType, 'name')
  }

  optional_assocs = {
    'site': (Site, 'name'),
    'group': (ClusterGroup, 'name')
  }

  if clusters is not None:
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

        print("Created cluster", cluster.name)
