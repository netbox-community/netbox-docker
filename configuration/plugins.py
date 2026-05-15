"""
Registra o plugin no NetBox.
Este arquivo e copiado para /etc/netbox/config/plugins.py durante o build.
"""

PLUGINS = [
    'netbox_hide_empty_fields',
    'netbox_topology_views',
]

PLUGINS_CONFIG = {
    'netbox_topology_views': {
        # Doc: https://github.com/netbox-community/netbox-topology-views
        # Diretorio dos icones (dentro de STATIC_ROOT). A pasta e criada no Dockerfile-Plugins.
        'static_image_directory': 'netbox_topology_views/img',
        # Salva as coordenadas dos nos automaticamente quando voce arrasta.
        'allow_coordinates_saving': True,
        'always_save_coordinates': True,
    },

    'netbox_hide_empty_fields': {
        # Comportamento padrao para usuarios que ainda nao configuraram nada.
        # True  = ja oculta campos vazios automaticamente na primeira visita
        # False = mostra tudo ate o usuario ativar manualmente
        'default_hide_empty': True,
    },
}
