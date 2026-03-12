from os import environ

from django.conf import settings
from users.choices import TokenVersionChoices
from users.models import Token, User


# Read secret from file
def _read_secret(secret_name: str, default: str | None = None) -> str | None:
    try:
        f = open("/run/secrets/" + secret_name, "r", encoding="utf-8")
    except EnvironmentError:
        return default
    else:
        with f:
            return f.readline().strip()


su_name = environ.get("SUPERUSER_NAME", "admin")
su_email = environ.get("SUPERUSER_EMAIL", "admin@example.com")
su_password = _read_secret("superuser_password", environ.get("SUPERUSER_PASSWORD", "admin"))
# Sets the superuser API Token, defaults to widely known default
if not environ.get("SUPERUSER_API_TOKEN"):
    print("⚠️ Warning: Defaulting to the old default admin token in your database. This token is widely known; please remove it.")
su_api_token = _read_secret(
    "superuser_api_token",
    environ.get("SUPERUSER_API_TOKEN", "0123456789abcdef0123456789abcdef01234567"),
)

# Sets the superuser API key, defaults to a randomly generated key.
su_api_key = _read_secret(
    "superuser_api_key",
    environ.get("SUPERUSER_API_KEY"),
)

if not User.objects.filter(username=su_name):
    u = User.objects.create_superuser(su_name, su_email, su_password)
    msg = ""
    if not settings.API_TOKEN_PEPPERS:
        print("⚠️ No API token will be created as API_TOKEN_PEPPERS is not set")
        msg = f"💡 Superuser Username: {su_name}, E-Mail: {su_email}"
    else:
        if su_api_key:
            t = Token.objects.create(user=u, token=su_api_token, version=TokenVersionChoices.V2, key=su_api_key)
        else:
            t = Token.objects.create(user=u, token=su_api_token, version=TokenVersionChoices.V2)
        msg = f"💡 Superuser Username: {su_name}, E-Mail: {su_email}, API Token: {su_api_token} (use with '{t.get_auth_header_prefix()}<Your token>')"
    print(msg)
