import sys

from django.contrib.auth.models import User
from startup_script_utils import load_yaml
from users.models import Token

users = load_yaml("/opt/netbox/initializers/users.yml")
if users is None:
    sys.exit()

for username, user_details in users.items():
    if not User.objects.filter(username=username):
        user = User.objects.create_user(
            username=username,
            password=user_details.get("password", 0) or User.objects.make_random_password(),
            first_name=user_details.get("first_name", ""),
            last_name=user_details.get("last_name", ""),
            email=user_details.get("email", "none"),
            is_staff=user_details.get("is_staff", False),
            is_active=user_details.get("is_active", True),
            is_superuser=user_details.get("is_superuser", False),
        )

        print("👤 Created user", username)

        if user_details.get("api_token", 0):
            Token.objects.create(user=user, key=user_details["api_token"])
