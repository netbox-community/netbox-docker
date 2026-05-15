#!/usr/bin/env bash
###############################################################################
# install-netbox-hide-empty-fields.sh
#
# Cria todos os arquivos do plugin "netbox-hide-empty-fields" dentro do
# diretorio do netbox-docker e, opcionalmente, executa o build/up.
#
# Uso:
#   chmod +x install-netbox-hide-empty-fields.sh
#   sudo ./install-netbox-hide-empty-fields.sh                    # diretorio padrao
#   sudo ./install-netbox-hide-empty-fields.sh /caminho/netbox-docker
#   sudo ./install-netbox-hide-empty-fields.sh /caminho --build   # ja faz build+up
#
# Testado em Ubuntu 24.04.
###############################################################################

set -euo pipefail

# ---------------------------------------------------------------------------
# Parametros
# ---------------------------------------------------------------------------
NETBOX_DOCKER_DIR="${1:-/home/rafitec/netbox-docker}"
DO_BUILD=0
for arg in "$@"; do
    if [[ "$arg" == "--build" ]]; then
        DO_BUILD=1
    fi
done

# Cores
C_OK="\033[1;32m"
C_WARN="\033[1;33m"
C_ERR="\033[1;31m"
C_INFO="\033[1;36m"
C_END="\033[0m"

log()  { echo -e "${C_INFO}[INFO]${C_END} $*"; }
ok()   { echo -e "${C_OK}[ OK ]${C_END} $*"; }
warn() { echo -e "${C_WARN}[WARN]${C_END} $*"; }
err()  { echo -e "${C_ERR}[ERRO]${C_END} $*" >&2; }

# ---------------------------------------------------------------------------
# Sanity checks
# ---------------------------------------------------------------------------
if [[ ! -d "$NETBOX_DOCKER_DIR" ]]; then
    err "Diretorio nao existe: $NETBOX_DOCKER_DIR"
    err "Passe o caminho correto como argumento, ex.:"
    err "  $0 /caminho/para/netbox-docker"
    exit 1
fi

cd "$NETBOX_DOCKER_DIR"
log "Trabalhando em: $(pwd)"

# ---------------------------------------------------------------------------
# Backup do que ja existe
# ---------------------------------------------------------------------------
TS="$(date +%Y%m%d-%H%M%S)"
for f in Dockerfile-Plugins plugin_requirements.txt; do
    if [[ -f "$f" ]]; then
        cp -v "$f" "${f}.bak-${TS}"
    fi
done
if [[ -d configuration ]]; then
    cp -rv configuration "configuration.bak-${TS}" 2>/dev/null || true
fi
if [[ -d plugins/netbox_hide_empty_fields ]]; then
    cp -rv plugins/netbox_hide_empty_fields "plugins/netbox_hide_empty_fields.bak-${TS}" 2>/dev/null || true
fi
ok "Backup criado com sufixo .bak-${TS}"

# ---------------------------------------------------------------------------
# Estrutura de diretorios
# ---------------------------------------------------------------------------
log "Criando estrutura de diretorios..."

PLUGIN_PKG="plugins/netbox_hide_empty_fields"
PLUGIN_SRC="${PLUGIN_PKG}/netbox_hide_empty_fields"

mkdir -p "configuration"
mkdir -p "${PLUGIN_SRC}/static/netbox_hide_empty_fields"
mkdir -p "${PLUGIN_SRC}/templates/netbox_hide_empty_fields/inc"

ok "Diretorios criados"

# ---------------------------------------------------------------------------
# Arquivo: Dockerfile-Plugins  (corrige o "pip: not found" usando uv)
# ---------------------------------------------------------------------------
log "Escrevendo Dockerfile-Plugins (usa uv pip - correto para NetBox 4.3+)..."
cat > Dockerfile-Plugins <<'DOCKERFILE_EOF'
###############################################################################
# Dockerfile-Plugins
#
# Build customizado do NetBox que instala o plugin "netbox-hide-empty-fields".
#
# IMPORTANTE: a partir do NetBox 4.3+, a imagem netboxcommunity/netbox NAO traz
# o binario `pip` no PATH. O gerenciador usado e o `uv` (em /usr/local/bin/uv).
# Esse e o motivo do erro "/bin/sh: 1: pip: not found".
#
# Referencias oficiais:
#   - https://github.com/netbox-community/netbox-docker/wiki/Using-Netbox-Plugins
#   - https://github.com/netbox-community/netbox-docker/issues/1453
###############################################################################

FROM netboxcommunity/netbox:latest

COPY plugins /plugins
COPY plugin_requirements.txt /opt/netbox/

# Instala o plugin local e quaisquer dependencias adicionais do PyPI.
# `uv pip` honra automaticamente o virtualenv em /opt/netbox/venv.
RUN /usr/local/bin/uv pip install --no-cache /plugins/netbox_hide_empty_fields \
 && /usr/local/bin/uv pip install --no-cache -r /opt/netbox/plugin_requirements.txt

# Registra o plugin no NetBox.
COPY configuration/configuration.py /etc/netbox/config/configuration.py
COPY configuration/plugins.py /etc/netbox/config/plugins.py

# Coleta os arquivos estaticos do plugin (JS/CSS).
RUN DEBUG="true" SECRET_KEY="dummydummydummydummydummydummydummydummydummydummy" \
    /opt/netbox/venv/bin/python /opt/netbox/netbox/manage.py collectstatic --no-input
DOCKERFILE_EOF
ok "Dockerfile-Plugins"

# ---------------------------------------------------------------------------
# Arquivo: plugin_requirements.txt
# ---------------------------------------------------------------------------
cat > plugin_requirements.txt <<'REQ_EOF'
# Lista de plugins adicionais do PyPI a instalar.
# O plugin local (netbox_hide_empty_fields) ja e instalado direto do diretorio
# /plugins no Dockerfile-Plugins, entao nao precisa estar listado aqui.
#
# Exemplo:
# netbox-topology-views
# netbox-acls
REQ_EOF
ok "plugin_requirements.txt"

# ---------------------------------------------------------------------------
# Preserva configuration/configuration.py do usuario (se nao existir, cria um vazio)
# ---------------------------------------------------------------------------
if [[ ! -f configuration/configuration.py ]]; then
    warn "configuration/configuration.py nao encontrado. Criando placeholder vazio."
    warn "Voce provavelmente quer revisar isso depois (ver configuration_example.py do netbox-docker)."
    cat > configuration/configuration.py <<'CFG_EOF'
# Configuracao do NetBox.
# Este arquivo foi criado automaticamente pelo instalador do plugin
# netbox-hide-empty-fields. Substitua pelo seu configuration.py original
# se voce ja tinha um.
import os

ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', '*').split(' ')
DATABASE = {
    'NAME':     os.environ.get('DB_NAME', 'netbox'),
    'USER':     os.environ.get('DB_USER', 'netbox'),
    'PASSWORD': os.environ.get('DB_PASSWORD', ''),
    'HOST':     os.environ.get('DB_HOST', 'localhost'),
    'PORT':     os.environ.get('DB_PORT', ''),
    'CONN_MAX_AGE': int(os.environ.get('DB_CONN_MAX_AGE', '300')),
}
REDIS = {
    'tasks': {
        'HOST':     os.environ.get('REDIS_HOST', 'localhost'),
        'PORT': int(os.environ.get('REDIS_PORT', 6379)),
        'PASSWORD': os.environ.get('REDIS_PASSWORD', ''),
        'DATABASE': int(os.environ.get('REDIS_DATABASE', 0)),
        'SSL':      os.environ.get('REDIS_SSL', 'false').lower() == 'true',
    },
    'caching': {
        'HOST':     os.environ.get('REDIS_CACHE_HOST', os.environ.get('REDIS_HOST', 'localhost')),
        'PORT': int(os.environ.get('REDIS_CACHE_PORT', os.environ.get('REDIS_PORT', 6379))),
        'PASSWORD': os.environ.get('REDIS_CACHE_PASSWORD', os.environ.get('REDIS_PASSWORD', '')),
        'DATABASE': int(os.environ.get('REDIS_CACHE_DATABASE', 1)),
        'SSL':      os.environ.get('REDIS_CACHE_SSL', 'false').lower() == 'true',
    },
}
SECRET_KEY = os.environ.get('SECRET_KEY', '')
CFG_EOF
fi

# ---------------------------------------------------------------------------
# Arquivo: configuration/plugins.py  (registra o plugin)
# ---------------------------------------------------------------------------
cat > configuration/plugins.py <<'PLUGINS_EOF'
"""
Registra o plugin no NetBox.
Este arquivo e copiado para /etc/netbox/config/plugins.py durante o build.
"""

PLUGINS = [
    'netbox_hide_empty_fields',
]

PLUGINS_CONFIG = {
    'netbox_hide_empty_fields': {
        # Comportamento padrao para usuarios que ainda nao configuraram nada.
        # True  = ja oculta campos vazios automaticamente na primeira visita
        # False = mostra tudo ate o usuario ativar manualmente
        'default_hide_empty': True,
    },
}
PLUGINS_EOF
ok "configuration/plugins.py"

# ---------------------------------------------------------------------------
# Arquivo: pyproject.toml do plugin
# ---------------------------------------------------------------------------
cat > "${PLUGIN_PKG}/pyproject.toml" <<'PYPROJECT_EOF'
[build-system]
requires = ["setuptools>=61.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "netbox-hide-empty-fields"
version = "0.1.0"
description = "Plugin NetBox 4.x para cada usuario ocultar campos vazios ou especificos nas views DCIM."
readme = "README.md"
requires-python = ">=3.10"
license = { text = "Apache-2.0" }
authors = [
    { name = "Rafitec" }
]
classifiers = [
    "Framework :: Django",
    "Programming Language :: Python :: 3",
    "Operating System :: OS Independent",
]
dependencies = []

[project.urls]
Homepage = "https://example.com/netbox-hide-empty-fields"

[tool.setuptools.packages.find]
include = ["netbox_hide_empty_fields*"]

[tool.setuptools.package-data]
netbox_hide_empty_fields = [
    "templates/**/*.html",
    "static/**/*.js",
    "static/**/*.css",
]
PYPROJECT_EOF
ok "${PLUGIN_PKG}/pyproject.toml"

# ---------------------------------------------------------------------------
# MANIFEST.in
# ---------------------------------------------------------------------------
cat > "${PLUGIN_PKG}/MANIFEST.in" <<'MANIFEST_EOF'
recursive-include netbox_hide_empty_fields/templates *
recursive-include netbox_hide_empty_fields/static *
include README.md
MANIFEST_EOF
ok "${PLUGIN_PKG}/MANIFEST.in"

# ---------------------------------------------------------------------------
# README do plugin
# ---------------------------------------------------------------------------
cat > "${PLUGIN_PKG}/README.md" <<'README_PLUGIN_EOF'
# netbox-hide-empty-fields

Plugin oficial NetBox 4.x que permite a cada usuario ocultar campos vazios
ou campos especificos nas detail views do app DCIM.

Acesso via menu: **Plugins > Hide Empty Fields - Minhas Preferencias**
Atalho: **Shift + H** ativa o modo edicao visual.
README_PLUGIN_EOF

# ---------------------------------------------------------------------------
# __init__.py  (PluginConfig)
# ---------------------------------------------------------------------------
cat > "${PLUGIN_SRC}/__init__.py" <<'INIT_EOF'
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
INIT_EOF
ok "${PLUGIN_SRC}/__init__.py"

# ---------------------------------------------------------------------------
# utils.py
# ---------------------------------------------------------------------------
cat > "${PLUGIN_SRC}/utils.py" <<'UTILS_EOF'
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
UTILS_EOF
ok "${PLUGIN_SRC}/utils.py"

# ---------------------------------------------------------------------------
# template_content.py
# ---------------------------------------------------------------------------
cat > "${PLUGIN_SRC}/template_content.py" <<'TC_EOF'
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
TC_EOF
ok "${PLUGIN_SRC}/template_content.py"

# ---------------------------------------------------------------------------
# forms.py
# ---------------------------------------------------------------------------
cat > "${PLUGIN_SRC}/forms.py" <<'FORMS_EOF'
"""
Formulario de configuracao das preferencias do usuario.
"""
from django import forms
from django.utils.translation import gettext_lazy as _


class UserHideEmptyForm(forms.Form):
    hide_empty = forms.BooleanField(
        label=_('Ocultar campos vazios automaticamente'),
        required=False,
        help_text=_(
            'Quando ativo, qualquer linha cujo valor seja "—" (vazio) '
            'sera ocultada nas views de detalhe do DCIM.'
        ),
    )
    hidden_fields = forms.CharField(
        label=_('Campos a ocultar (um por linha)'),
        required=False,
        widget=forms.Textarea(attrs={'rows': 10, 'class': 'form-control'}),
        help_text=_(
            'Digite o texto EXATO do rotulo do campo, exatamente como '
            'aparece na pagina (ex.: "Fluxo de Ar", "Airflow", "Status"). '
            'Um campo por linha.'
        ),
    )

    def clean_hidden_fields(self):
        raw = self.cleaned_data.get('hidden_fields') or ''
        items = []
        for line in raw.splitlines():
            line = line.strip()
            if line:
                items.append(line)
        return items
FORMS_EOF
ok "${PLUGIN_SRC}/forms.py"

# ---------------------------------------------------------------------------
# views.py
# ---------------------------------------------------------------------------
cat > "${PLUGIN_SRC}/views.py" <<'VIEWS_EOF'
"""
View da tela de configuracao do plugin.
"""
from django.contrib import messages
from django.contrib.auth.mixins import LoginRequiredMixin
from django.shortcuts import redirect, render
from django.urls import reverse
from django.utils.translation import gettext_lazy as _
from django.views import View

from .forms import UserHideEmptyForm
from .utils import get_user_preferences, set_user_preferences


class UserSettingsView(LoginRequiredMixin, View):
    template_name = 'netbox_hide_empty_fields/settings.html'

    def get(self, request):
        prefs = get_user_preferences(request.user)
        form = UserHideEmptyForm(initial={
            'hide_empty': prefs['hide_empty'],
            'hidden_fields': '\n'.join(prefs['hidden_fields']),
        })
        return render(request, self.template_name, {'form': form})

    def post(self, request):
        form = UserHideEmptyForm(request.POST)
        if form.is_valid():
            set_user_preferences(
                user=request.user,
                hide_empty=form.cleaned_data['hide_empty'],
                hidden_fields=form.cleaned_data['hidden_fields'],
            )
            messages.success(request, _('Preferencias salvas com sucesso.'))
            return redirect(reverse('plugins:netbox_hide_empty_fields:settings'))
        return render(request, self.template_name, {'form': form})
VIEWS_EOF
ok "${PLUGIN_SRC}/views.py"

# ---------------------------------------------------------------------------
# urls.py
# ---------------------------------------------------------------------------
cat > "${PLUGIN_SRC}/urls.py" <<'URLS_EOF'
"""
URLs do plugin.
"""
from django.urls import path

from . import views

app_name = 'netbox_hide_empty_fields'

urlpatterns = [
    path('settings/', views.UserSettingsView.as_view(), name='settings'),
]
URLS_EOF
ok "${PLUGIN_SRC}/urls.py"

# ---------------------------------------------------------------------------
# navigation.py
# ---------------------------------------------------------------------------
cat > "${PLUGIN_SRC}/navigation.py" <<'NAV_EOF'
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
NAV_EOF
ok "${PLUGIN_SRC}/navigation.py"

# ---------------------------------------------------------------------------
# templates/.../inc/inject.html
# ---------------------------------------------------------------------------
cat > "${PLUGIN_SRC}/templates/netbox_hide_empty_fields/inc/inject.html" <<'INJECT_EOF'
{% load static %}

<script id="netbox-hef-prefs" type="application/json">{{ hef_preferences_json|safe }}</script>
<link rel="stylesheet" href="{% static 'netbox_hide_empty_fields/hide-empty.css' %}">
<script src="{% static 'netbox_hide_empty_fields/hide-empty.js' %}" defer></script>
INJECT_EOF
ok "${PLUGIN_SRC}/templates/.../inject.html"

# ---------------------------------------------------------------------------
# templates/.../settings.html
# ---------------------------------------------------------------------------
cat > "${PLUGIN_SRC}/templates/netbox_hide_empty_fields/settings.html" <<'SETTINGS_EOF'
{% extends 'base/layout.html' %}
{% load helpers %}

{% block title %}Hide Empty Fields - Preferencias{% endblock %}

{% block content %}
<div class="row">
  <div class="col col-md-8 mx-auto">
    <div class="card">
      <h2 class="card-header">Hide Empty Fields</h2>
      <div class="card-body">
        <p class="text-muted">
          Estas preferencias sao individuais do seu usuario.
          Outros usuarios nao serao afetados.
        </p>

        <form method="post">
          {% csrf_token %}

          <div class="mb-3 form-check form-switch">
            {{ form.hide_empty }}
            <label class="form-check-label" for="{{ form.hide_empty.id_for_label }}">
              {{ form.hide_empty.label }}
            </label>
            <div class="form-text">{{ form.hide_empty.help_text }}</div>
          </div>

          <div class="mb-3">
            <label class="form-label" for="{{ form.hidden_fields.id_for_label }}">
              {{ form.hidden_fields.label }}
            </label>
            {{ form.hidden_fields }}
            <div class="form-text">{{ form.hidden_fields.help_text }}</div>
          </div>

          <div class="text-end">
            <a href="{% url 'home' %}" class="btn btn-outline-secondary">Cancelar</a>
            <button type="submit" class="btn btn-primary">Salvar preferencias</button>
          </div>
        </form>
      </div>
    </div>

    <div class="card mt-3">
      <h5 class="card-header">Dica</h5>
      <div class="card-body">
        <p>
          Em qualquer pagina de detalhe DCIM (ex.: <code>/dcim/devices/1/</code>),
          aperte <kbd>Shift</kbd>+<kbd>H</kbd> para entrar no <strong>modo edicao</strong>:
          aparecera um botao <code>[x]</code> ao lado do nome de cada campo.
          Clique para adicionar o campo a sua lista de campos ocultos.
        </p>
        <p class="mb-0">
          Os campos sao identificados pelo <strong>texto exato do label</strong>,
          porque o NetBox pode estar em diferentes idiomas.
        </p>
      </div>
    </div>
  </div>
</div>
{% endblock %}
SETTINGS_EOF
ok "${PLUGIN_SRC}/templates/.../settings.html"

# ---------------------------------------------------------------------------
# static/.../hide-empty.css
# ---------------------------------------------------------------------------
cat > "${PLUGIN_SRC}/static/netbox_hide_empty_fields/hide-empty.css" <<'CSS_EOF'
/* netbox-hide-empty-fields */

tr.hef-hidden {
    display: none !important;
}

.card.hef-card-empty {
    opacity: 0.35;
}

body.hef-edit-mode tr.hef-hidden {
    display: table-row !important;
    opacity: 0.4;
}

.hef-hide-btn {
    border: none;
    background: #dc3545;
    color: white;
    margin-left: 0.5rem;
    border-radius: 0.25rem;
    padding: 0 0.4rem;
    font-size: 0.85rem;
    line-height: 1.1;
    cursor: pointer;
}
.hef-hide-btn:hover {
    background: #b02a37;
}

#hef-collected-panel {
    position: fixed;
    right: 1rem;
    bottom: 1rem;
    width: 320px;
    background: #1f2937;
    color: #f9fafb;
    border-radius: 0.5rem;
    box-shadow: 0 10px 25px rgba(0, 0, 0, 0.3);
    z-index: 99999;
    font-family: inherit;
    padding: 0.5rem;
}
#hef-collected-panel .hef-panel-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-weight: 600;
    padding-bottom: 0.25rem;
    border-bottom: 1px solid rgba(255,255,255,0.15);
    margin-bottom: 0.5rem;
}
#hef-collected-panel .hef-panel-close {
    background: transparent;
    border: none;
    color: white;
    font-size: 1.25rem;
    cursor: pointer;
    line-height: 1;
}
#hef-collected-panel textarea {
    width: 100%;
    min-height: 160px;
    background: #111827;
    color: #f9fafb;
    border: 1px solid #374151;
    border-radius: 0.25rem;
    padding: 0.25rem;
    font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
    font-size: 0.8rem;
    resize: vertical;
}
#hef-collected-panel .hef-panel-footer {
    margin-top: 0.5rem;
    opacity: 0.85;
}
CSS_EOF
ok "${PLUGIN_SRC}/static/.../hide-empty.css"

# ---------------------------------------------------------------------------
# static/.../hide-empty.js
# ---------------------------------------------------------------------------
cat > "${PLUGIN_SRC}/static/netbox_hide_empty_fields/hide-empty.js" <<'JS_EOF'
/*
 * netbox-hide-empty-fields
 * Roda em qualquer pagina DCIM. Le as preferencias do usuario (renderizadas
 * no <script id="netbox-hef-prefs"> pelo template inject.html) e oculta:
 *   1. Toda <tr> cujo segundo <td> contenha apenas <span class="text-muted">—</span>
 *   2. Toda <tr> cujo <th> (label) corresponda a um item em hidden_fields.
 *
 * Modo edicao: Shift+H ativa botoes [×] em cada label para selecionar campos.
 */
(function () {
  'use strict';

  const PREFS_EL = document.getElementById('netbox-hef-prefs');
  if (!PREFS_EL) return;

  let prefs;
  try {
    prefs = JSON.parse(PREFS_EL.textContent || '{}');
  } catch (e) {
    console.warn('[hide-empty-fields] preferencias invalidas:', e);
    prefs = {};
  }

  const hideEmpty = !!prefs.hide_empty;
  const hiddenFields = new Set(
    Array.isArray(prefs.hidden_fields) ? prefs.hidden_fields.map(s => String(s).trim()) : []
  );

  function isEmptyCell(td) {
    if (!td) return false;
    const meaningful = td.querySelector('a, span.badge, table, ul, ol, code, pre, button, .form-control');
    if (meaningful) return false;
    const text = (td.textContent || '').trim();
    if (!text) return true;
    if (text === '\u2014' || text === '-' || text === 'None') return true;
    const muted = td.querySelector('span.text-muted');
    if (muted && td.children.length === 1 && (muted.textContent || '').trim() === '\u2014') {
      return true;
    }
    return false;
  }

  function getLabelText(tr) {
    const th = tr.querySelector('th');
    if (!th) return '';
    return (th.textContent || '').replace(/\s+/g, ' ').trim();
  }

  function applyHiding(root) {
    const scope = root || document;
    const rows = scope.querySelectorAll('tr');
    let hiddenCount = 0;

    rows.forEach(tr => {
      const th = tr.querySelector(':scope > th');
      const tds = tr.querySelectorAll(':scope > td');
      if (!th || tds.length === 0) return;

      const label = getLabelText(tr);
      const valueCell = tds[0];

      let hide = false;

      if (hiddenFields.has(label)) {
        hide = true;
      }
      if (!hide && hideEmpty && isEmptyCell(valueCell)) {
        hide = true;
      }

      if (hide) {
        tr.classList.add('hef-hidden');
        hiddenCount++;
      } else {
        tr.classList.remove('hef-hidden');
      }
    });

    document.querySelectorAll('.card').forEach(card => {
      const rs = card.querySelectorAll('table tr');
      if (rs.length === 0) return;
      const visible = Array.from(rs).filter(r => !r.classList.contains('hef-hidden'));
      if (visible.length === 0 && rs.length > 0) {
        card.classList.add('hef-card-empty');
      } else {
        card.classList.remove('hef-card-empty');
      }
    });

    if (window.console && hiddenCount > 0) {
      console.info('[hide-empty-fields] ' + hiddenCount + ' linha(s) oculta(s).');
    }
  }

  // ============ MODO EDICAO ============
  let editMode = false;
  const collected = new Set(hiddenFields);

  function toggleEditMode() {
    editMode = !editMode;
    document.body.classList.toggle('hef-edit-mode', editMode);

    document.querySelectorAll('tr').forEach(tr => {
      const existing = tr.querySelector('.hef-hide-btn');
      if (existing) existing.remove();

      if (!editMode) return;

      const th = tr.querySelector(':scope > th');
      if (!th) return;
      const label = getLabelText(tr);
      if (!label) return;

      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'hef-hide-btn';
      btn.title = 'Ocultar o campo "' + label + '"';
      btn.textContent = '\u00d7';
      btn.addEventListener('click', function (ev) {
        ev.preventDefault();
        ev.stopPropagation();
        collected.add(label);
        tr.classList.add('hef-hidden');
        showCollectedPanel();
      });
      th.appendChild(btn);
    });

    if (editMode) {
      showCollectedPanel();
    } else {
      hideCollectedPanel();
    }
  }

  function showCollectedPanel() {
    let panel = document.getElementById('hef-collected-panel');
    if (!panel) {
      panel = document.createElement('div');
      panel.id = 'hef-collected-panel';
      panel.innerHTML =
        '<div class="hef-panel-header">' +
        '<span class="hef-panel-title">Campos selecionados (0)</span>' +
        '<button type="button" class="hef-panel-close" title="Fechar">\u00d7</button>' +
        '</div>' +
        '<textarea readonly></textarea>' +
        '<div class="hef-panel-footer">' +
        '<small>Copie e cole em <em>Preferencias do plugin</em> para salvar.</small>' +
        '</div>';
      document.body.appendChild(panel);
      panel.querySelector('.hef-panel-close').addEventListener('click', toggleEditMode);
    }
    panel.querySelector('.hef-panel-title').textContent =
      'Campos selecionados (' + collected.size + ')';
    panel.querySelector('textarea').value = Array.from(collected).join('\n');
    panel.style.display = 'block';
  }

  function hideCollectedPanel() {
    const panel = document.getElementById('hef-collected-panel');
    if (panel) panel.style.display = 'none';
  }

  document.addEventListener('keydown', function (e) {
    const t = e.target;
    if (t && (t.tagName === 'INPUT' || t.tagName === 'TEXTAREA' || t.isContentEditable)) {
      return;
    }
    if (e.shiftKey && (e.key === 'H' || e.key === 'h')) {
      e.preventDefault();
      toggleEditMode();
    }
  });

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () { applyHiding(); });
  } else {
    applyHiding();
  }

  const mo = new MutationObserver(function () { applyHiding(); });
  mo.observe(document.body, { childList: true, subtree: true });
})();
JS_EOF
ok "${PLUGIN_SRC}/static/.../hide-empty.js"

# ---------------------------------------------------------------------------
# Verifica docker-compose.override.yml
# ---------------------------------------------------------------------------
if [[ ! -f docker-compose.override.yml ]]; then
    warn "docker-compose.override.yml nao encontrado. Criando um basico."
    cat > docker-compose.override.yml <<'COMPOSE_EOF'
services:
  netbox:
    image: netbox:latest-plugins
    pull_policy: never
    ports:
      - 8000:8080
    build:
      context: .
      dockerfile: Dockerfile-Plugins
  netbox-worker:
    image: netbox:latest-plugins
    pull_policy: never
  netbox-housekeeping:
    image: netbox:latest-plugins
    pull_policy: never
COMPOSE_EOF
    ok "docker-compose.override.yml criado"
else
    log "docker-compose.override.yml ja existe -- nao foi alterado."
    warn "Verifique se ele aponta para 'dockerfile: Dockerfile-Plugins'."
fi

# ---------------------------------------------------------------------------
# Resumo
# ---------------------------------------------------------------------------
echo
ok "Todos os arquivos foram criados em $(pwd)"
echo
log "Estrutura criada:"
find Dockerfile-Plugins plugin_requirements.txt configuration plugins -maxdepth 6 2>/dev/null | sed 's|^|  |'
echo

# ---------------------------------------------------------------------------
# Build opcional
# ---------------------------------------------------------------------------
if [[ "$DO_BUILD" == "1" ]]; then
    echo
    log "Iniciando docker compose build --no-cache (pode demorar alguns minutos)..."
    docker compose build --no-cache
    log "Subindo containers..."
    docker compose up -d
    echo
    ok "NetBox de pe! Acesse e va em Plugins > 'Hide Empty Fields - Minhas Preferencias'."
else
    cat <<'NEXT_EOF'

==============================================================================
PROXIMOS PASSOS
==============================================================================
A partir deste diretorio, execute:

   docker compose build --no-cache
   docker compose up -d

Depois acesse o NetBox e va em:
   Menu superior > Plugins > "Hide Empty Fields - Minhas Preferencias"

DICA: Em qualquer pagina /dcim/devices/<id>/ aperte Shift+H para entrar no
modo edicao e marcar campos a ocultar visualmente.

==============================================================================
NEXT_EOF
fi
