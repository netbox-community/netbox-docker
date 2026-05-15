"""
PluginTemplateExtension que injeta JS nas views DCIM.

Doc oficial:
https://netboxlabs.com/docs/netbox/plugins/development/views/
"""
import json

from netbox.plugins import PluginTemplateExtension

from .utils import get_user_preferences

DCIM_MODELS = [
    'dcim.device',
    'dcim.site',
    'dcim.sitegroup',
    'dcim.region',
    'dcim.location',
    'dcim.rack',
    'dcim.rackgroup',
    'dcim.rackrole',
    'dcim.racktype',
    'dcim.rackreservation',
    'dcim.devicetype',
    'dcim.devicerole',
    'dcim.manufacturer',
    'dcim.platform',
    'dcim.module',
    'dcim.moduletype',
    'dcim.moduletypeprofile',
    'dcim.modulebay',
    'dcim.interface',
    'dcim.consoleport',
    'dcim.consoleserverport',
    'dcim.powerport',
    'dcim.poweroutlet',
    'dcim.frontport',
    'dcim.rearport',
    'dcim.devicebay',
    'dcim.inventoryitem',
    'dcim.inventoryitemrole',
    'dcim.cable',
    'dcim.virtualchassis',
    'dcim.virtualdevicecontext',
    'dcim.powerpanel',
    'dcim.powerfeed',
    'dcim.macaddress',
]


class HideEmptyFieldsInjector(PluginTemplateExtension):
    models = DCIM_MODELS

    def full_width_page(self):
        request = self.context.get('request')
        prefs = get_user_preferences(request.user) if request else {}
        return self.render(
            'netbox_hide_empty_fields/inc/inject.html',
            extra_context={
                'hef_preferences_json': json.dumps(prefs),
            },
        )


template_extensions = [HideEmptyFieldsInjector]
