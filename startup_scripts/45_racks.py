from dcim.models import Site, RackRole, Rack, RackGroup
from tenancy.models import Tenant
from extras.models import CustomField, CustomFieldValue
from dcim.constants import RACK_TYPE_CHOICES, RACK_WIDTH_CHOICES
from ruamel.yaml import YAML

with open('/opt/netbox/initializers/racks.yml', 'r') as stream:
  yaml = YAML(typ='safe')
  racks = yaml.load(stream)

  optional_assocs = dict(role=RackRole, tenant=Tenant, group=RackGroup)

  if racks is not None:
    for rack_params in racks:
      custom_fields = rack_params.pop('custom_fields', None)

      rack_params['site'] = Site.objects.get(name=rack_params.pop('site'))

      for param_name, model in optional_assoc.items():
        if param_name in rack_params:
          rack_params[param_name] = model.objects.get(name=rack_params.pop(param_name))

      for rack_type in RACK_TYPE_CHOICES:
        if rack_params['type'] in rack_type:
          rack_params['type'] = rack_type[0]

      for rack_width in RACK_WIDTH_CHOICES:
        if rack_params['width'] in rack_width:
          rack_params['width'] = rack_width[0]

      rack, created = Rack.objects.get_or_create(**rack_params)

      if created:
        if custom_fields is not None:
          for cf_name, cf_value in custom_fields.items():
            custom_field = CustomField.objects.get(name=cf_name)
            custom_field_value = CustomFieldValue.objects.create(field=custom_field, obj=rack, value=cf_value)

            rack.custom_field_values.add(custom_field_value)

        print("Created rack", rack.site, rack.name)
