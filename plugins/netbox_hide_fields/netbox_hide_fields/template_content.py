from extras.plugins import PluginTemplateExtension


class HideFieldsExtension(PluginTemplateExtension):

    models = ['dcim.device']

    def javascript(self):
        return """
<script src="/static/netbox_hide_fields/js/hide_fields.js"></script>
"""


template_extensions = [HideFieldsExtension]
