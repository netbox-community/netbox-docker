import sys

from django.contrib.contenttypes.models import ContentType
from extras.models import CustomLink
from startup_script_utils import load_yaml

custom_links = load_yaml("/opt/netbox/initializers/custom_links.yml")

if custom_links is None:
    sys.exit()


def get_content_type_id(content_type):
    try:
        return ContentType.objects.get(model=content_type).id
    except ContentType.DoesNotExist:
        pass


for link in custom_links:
    content_type = link.pop("content_type")
    link["content_type_id"] = get_content_type_id(content_type)
    if link["content_type_id"] is None:
        print(
            "⚠️ Unable to create Custom Link '{0}': The content_type '{1}' is unknown".format(
                link.get("name"), content_type
            )
        )
        continue

    custom_link, created = CustomLink.objects.get_or_create(**link)
    if created:
        print("🔗 Created Custom Link '{0}'".format(custom_link.name))
