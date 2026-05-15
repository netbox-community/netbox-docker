from extras.plugins import PluginConfig

class EmptyFieldsHiderConfig(PluginConfig):
    
    name = 'empty_fields_hider'
    verbose_name = 'Empty Fields Hider'
    description = 'Hides empty fields in device and virtual machine details.'
    version = '1.0'
    
config = EmptyFieldsHiderConfig()
