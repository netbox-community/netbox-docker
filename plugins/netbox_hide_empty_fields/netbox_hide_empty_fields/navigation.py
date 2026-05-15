"""
Item de menu no NetBox.
Doc: https://netboxlabs.com/docs/netbox/plugins/development/navigation/
"""
from netbox.plugins import PluginMenuItem

menu_items = (
    PluginMenuItem(
        link='plugins:netbox_hide_empty_fields:settings',
        link_text='Hide Empty Fields - Minhas Preferencias',
    ),
)
