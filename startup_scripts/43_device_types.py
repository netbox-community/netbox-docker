from dcim.models import DeviceType, Manufacturer
from extras.models import CustomField, CustomFieldValue
from ruamel.yaml import YAML

with open('/opt/netbox/initializers/device_types.yml', 'r') as stream:
  yaml = YAML(typ='safe')
  device_types = yaml.load(stream)

  if device_types is not None:
    for device_type_params in device_types:
      custom_fields = device_type_params.pop('custom_fields', None)

      manufacturer = Manufacturer.objects.get(name=device_type_params.pop('manufacturer'))
      device_type_params['manufacturer'] = manufacturer

      device_type, created = DeviceType.objects.get_or_create(**device_type_params)

      if created:
        if custom_fields is not None:
          for cf_name, cf_value in custom_fields.items():
            custom_field = CustomField.objects.get(name=cf_name)
            custom_field_value = CustomFieldValue.objects.create(field=custom_field, obj=device_type, value=cf_value)

            device_type.custom_field_values.add(custom_field_value)

        print("Created device type", device_type.manufacturer, device_type.model)

