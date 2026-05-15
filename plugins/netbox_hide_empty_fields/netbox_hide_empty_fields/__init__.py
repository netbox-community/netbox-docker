"""
NetBox Hide Empty Fields Plugin
================================
Plugin oficial NetBox 4.x que permite a cada usuario ocultar campos vazios
ou campos especificos nas paginas de detalhe do modulo DCIM.

Referencias:
- https://netboxlabs.com/docs/netbox/plugins/development/
- https://netboxlabs.com/docs/netbox/plugins/development/views/
- https://netboxlabs.com/docs/netbox/features/user-preferences/
"""
from netbox.plugins import PluginConfig

__version__ = '0.1.0'


class HideEmptyFieldsConfig(PluginConfig):
    name = 'netbox_hide_empty_fields'
    verbose_name = 'Hide Empty Fields'
    description = 'Permite cada usuario ocultar campos vazios ou campos especificos nas views DCIM.'
    version = __version__
    author = 'Rafitec'
    author_email = 'admin@example.com'
    base_url = 'hide-empty-fields'
    min_version = '4.0.0'
    max_version = '4.9.99'

    default_settings = {
        'default_hide_empty': True,
        'extra_apps': [],
    }

    required_settings = []


config = HideEmptyFieldsConfig
