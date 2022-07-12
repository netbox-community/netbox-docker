import sys

from django.contrib.auth.models import User
from startup_script_utils import load_yaml
from users.models import Token

users = load_yaml("/opt/netbox/initializers/users.yml")
if users is None:
    sys.exit()

for username, user_details in users.items():

    api_token = user_details.pop("api_token", Token.generate_key())
    password = user_details.pop("password", User.objects.make_random_password())

    user, created = User.objects.get_or_create(username=username, defaults=user_details)

    if created:
        user.set_password(password)
        user.save()

        if api_token:
            Token.objects.get_or_create(user=user, key=api_token)

        print("👤 Created user", username)
