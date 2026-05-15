"""
Helpers para ler/gravar as preferencias do usuario.

NetBox armazena preferencias por usuario no model users.UserConfig,
acessivel via request.user.config. A API tem .get('dotted.path') e
.set('dotted.path', value, commit=True).

Documentacao:
- https://netboxlabs.com/docs/netbox/features/user-preferences/
"""
from netbox.plugins import get_plugin_config

PREF_ROOT = 'plugins.netbox_hide_empty_fields'
PREF_HIDE_EMPTY = f'{PREF_ROOT}.hide_empty'
PREF_HIDDEN_FIELDS = f'{PREF_ROOT}.hidden_fields'


def get_user_preferences(user):
    default_hide_empty = bool(
        get_plugin_config('netbox_hide_empty_fields', 'default_hide_empty', True)
    )

    if not user or not user.is_authenticated:
        return {'hide_empty': default_hide_empty, 'hidden_fields': []}

    try:
        userconfig = user.config
    except Exception:
        return {'hide_empty': default_hide_empty, 'hidden_fields': []}

    hide_empty = userconfig.get(PREF_HIDE_EMPTY, default_hide_empty)
    hidden_fields = userconfig.get(PREF_HIDDEN_FIELDS, []) or []
    if not isinstance(hidden_fields, list):
        hidden_fields = []

    return {
        'hide_empty': bool(hide_empty),
        'hidden_fields': [str(f).strip() for f in hidden_fields if str(f).strip()],
    }


def set_user_preferences(user, hide_empty, hidden_fields):
    if not user or not user.is_authenticated:
        return
    userconfig = user.config
    userconfig.set(PREF_HIDE_EMPTY, bool(hide_empty), commit=False)
    cleaned = [str(f).strip() for f in (hidden_fields or []) if str(f).strip()]
    userconfig.set(PREF_HIDDEN_FIELDS, cleaned, commit=True)
