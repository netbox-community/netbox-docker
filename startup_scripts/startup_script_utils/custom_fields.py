from django.contrib.contenttypes.models import ContentType
from django.core.exceptions import ObjectDoesNotExist
from extras.models import CustomField


def set_custom_fields_values(entity, custom_field_data):
    if not custom_field_data:
        return

    missing_cfs = []
    save = False
    for key, value in custom_field_data.items():
        try:
            cf = CustomField.objects.get(name=key)
        except ObjectDoesNotExist:
            missing_cfs.append(key)
        else:
            ct = ContentType.objects.get_for_model(entity)
            if ct not in cf.content_types.all():
                print(
                    f"⚠️ Custom field {key} is not enabled for {entity}'s model!"
                    "Please check the 'on_objects' for that custom field in custom_fields.yml"
                )
            elif key not in entity.custom_field_data:
                entity.custom_field_data[key] = value
                save = True

    if missing_cfs:
        raise Exception(
            f"⚠️ Custom field(s) '{missing_cfs}' requested for {entity} but not found in Netbox!"
            "Please chceck the custom_fields.yml"
        )

    if save:
        entity.save()


def pop_custom_fields(params):
    if "custom_field_data" in params:
        return params.pop("custom_field_data")
    elif "custom_fields" in params:
        print("⚠️ Please rename 'custom_fields' to 'custom_field_data'!")
        return params.pop("custom_fields")

    return None
