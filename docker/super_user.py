from os import environ
from users.models import Token, User
from users.choices import TokenVersionChoices
from django.conf import settings


# Read secret from file
def _read_secret(secret_name: str, default: str | None = None) -> str | None:
    try:
        f = open("/run/secrets/" + secret_name, "r", encoding="utf-8")
    except EnvironmentError:
        return default
    else:
        with f:
            return f.readline().strip()


su_name = environ.get("SUPERUSER_NAME")
su_email = environ.get("SUPERUSER_EMAIL")
su_password = _read_secret("superuser_password", environ.get("SUPERUSER_PASSWORD"))
su_api_token = _read_secret("superuser_api_token", environ.get("SUPERUSER_API_TOKEN"))

if not User.objects.filter(username=su_name):
    u = User.objects.create_superuser(su_name, su_email, su_password)
    msg = ""
    if not settings.API_TOKEN_PEPPERS:
        print("⚠️ No API token will be created as API_TOKEN_PEPPERS is not set")
        msg = f"💡 Superuser Username: {su_name}, E-Mail: {su_email}"
    else:
        t = Token.objects.create(user=u, token=su_api_token, version=TokenVersionChoices.V2)
        msg = f"💡 Superuser Username: {su_name}, E-Mail: {su_email}, API Token: {t} (use with '{t.get_auth_header_prefix()}<Your token>')"
    print(msg)
