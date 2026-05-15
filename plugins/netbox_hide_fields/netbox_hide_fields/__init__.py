from extras.plugins import PluginConfig


class NetBoxHideFieldsConfig(PluginConfig):
    name = "netbox_hide_fields"
    verbose_name = "NetBox Hide Fields"
    description = "Hide empty fields dynamically"
    version = "0.1"
    author = "Rafitec"
    base_url = "hide-fields"


config = NetBoxHideFieldsConfig
