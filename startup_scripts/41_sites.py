from dcim.models import Region, Site
from extras.models import CustomField, CustomFieldValue
from tenancy.models import Tenant
from ruamel.yaml import YAML

with open('/opt/netbox/initializers/sites.yml', 'r') as stream:
  yaml = YAML(typ='safe')
  sites = yaml.load(stream)

  optional_assocs = {
    'region': (Region, 'name'),
    'tenant': (Tenant, 'name')
  }

  if sites is not None:
    for params in sites:

      for assoc, details in optional_assocs.items():
        if assoc in params:
          model, field = details
          query = { field: params.pop(assoc) }

          params[assoc] = model.objects.get(**query)

      site, created = Site.objects.get_or_create(**params)

      if created:
        if custom_fields is not None:
          for cf_name, cf_value in custom_fields.items():
            custom_field = CustomField.objects.get(name=cf_name)
            custom_field_value = CustomFieldValue.objects.create(
              field=custom_field,
              obj=device_type,
              value=cf_value
            )

            site.custom_field_values.add(custom_field_value)

        print("Created site", site.name)
