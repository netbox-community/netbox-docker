#!/usr/bin/env bash
###############################################################################
# install-netbox-topology-views.sh
#
# Instala o plugin netbox-topology-views (https://github.com/netbox-community/
# netbox-topology-views) num netbox-docker em execucao, mantendo intacto
# qualquer outro plugin ja instalado (ex.: netbox_hide_empty_fields).
#
# O que o script faz:
#   1. Faz backup dos arquivos que serao modificados.
#   2. Adiciona `netbox-topology-views` ao plugin_requirements.txt
#      (somente se ainda nao estiver listado).
#   3. Adiciona `netbox_topology_views` ao PLUGINS de configuration/plugins.py
#      (preservando outros plugins) e injeta a sua PLUGINS_CONFIG.
#   4. Regenera o Dockerfile-Plugins adicionando:
#         - a pasta /opt/netbox/netbox/static/netbox_topology_views/img
#           (exigida pelo README do plugin para servir os icones)
#         - a migrate da app netbox_topology_views durante o build
#   5. Opcionalmente roda `docker compose build --no-cache && docker compose up -d`.
#
# Uso:
#   chmod +x install-netbox-topology-views.sh
#   sudo ./install-netbox-topology-views.sh                     # padrao
#   sudo ./install-netbox-topology-views.sh /home/rafitec/netbox-docker
#   sudo ./install-netbox-topology-views.sh /caminho --build    # ja builda
#
# Testado em Ubuntu 24.04 / netbox-docker com NetBox 4.6.
###############################################################################

set -euo pipefail

NETBOX_DOCKER_DIR="${1:-/home/rafitec/netbox-docker}"
DO_BUILD=0
for arg in "$@"; do
    if [[ "$arg" == "--build" ]]; then DO_BUILD=1; fi
done

C_OK="\033[1;32m"; C_WARN="\033[1;33m"; C_ERR="\033[1;31m"
C_INFO="\033[1;36m"; C_END="\033[0m"
log()  { echo -e "${C_INFO}[INFO]${C_END} $*"; }
ok()   { echo -e "${C_OK}[ OK ]${C_END} $*"; }
warn() { echo -e "${C_WARN}[WARN]${C_END} $*"; }
err()  { echo -e "${C_ERR}[ERRO]${C_END} $*" >&2; }

# ---------------------------------------------------------------------------
# Sanity
# ---------------------------------------------------------------------------
if [[ ! -d "$NETBOX_DOCKER_DIR" ]]; then
    err "Diretorio nao existe: $NETBOX_DOCKER_DIR"
    exit 1
fi
cd "$NETBOX_DOCKER_DIR"
log "Trabalhando em: $(pwd)"

if [[ ! -f Dockerfile-Plugins ]]; then
    err "Dockerfile-Plugins nao encontrado em $(pwd)."
    err "Esse script presume que voce ja executou install-netbox-hide-empty-fields.sh ou tem um Dockerfile-Plugins valido."
    exit 1
fi

TS="$(date +%Y%m%d-%H%M%S)"

# ---------------------------------------------------------------------------
# Backup
# ---------------------------------------------------------------------------
for f in Dockerfile-Plugins plugin_requirements.txt configuration/plugins.py; do
    if [[ -f "$f" ]]; then
        cp -v "$f" "${f}.bak-${TS}"
    fi
done
ok "Backups criados (sufixo .bak-${TS})"

# ---------------------------------------------------------------------------
# 1) plugin_requirements.txt: adiciona linha sem duplicar
# ---------------------------------------------------------------------------
log "Garantindo netbox-topology-views em plugin_requirements.txt..."

if ! grep -E '^[[:space:]]*netbox-topology-views' plugin_requirements.txt >/dev/null 2>&1; then
    # garante que o arquivo termina em newline antes de appendar
    [[ -s plugin_requirements.txt ]] && tail -c1 plugin_requirements.txt | read -r _ || echo >> plugin_requirements.txt
    echo "netbox-topology-views" >> plugin_requirements.txt
    ok "Adicionado a plugin_requirements.txt"
else
    log "Ja estava listado, nao mexi."
fi

# ---------------------------------------------------------------------------
# 2) configuration/plugins.py: adiciona plugin sem remover outros
# ---------------------------------------------------------------------------
log "Atualizando configuration/plugins.py..."

# Usa python para fazer um patch seguro (preserva strings, formato, outros plugins).
python3 - "$NETBOX_DOCKER_DIR/configuration/plugins.py" <<'PYEOF'
import re, sys, pathlib, textwrap

path = pathlib.Path(sys.argv[1])
src = path.read_text(encoding="utf-8")

# 1) Garante que 'netbox_topology_views' esteja em PLUGINS = [...]
plugins_match = re.search(r"PLUGINS\s*=\s*\[(.*?)\]", src, re.DOTALL)
if not plugins_match:
    print("[python] PLUGINS list nao encontrada -- gerando do zero")
    src = (
        "PLUGINS = [\n"
        "    'netbox_hide_empty_fields',\n"
        "    'netbox_topology_views',\n"
        "]\n\n"
        + src
    )
else:
    body = plugins_match.group(1)
    if "netbox_topology_views" not in body:
        # insere antes do colchete final, mantendo a indentacao
        new_body = body.rstrip()
        if new_body and not new_body.rstrip().endswith(","):
            new_body += ","
        new_body += "\n    'netbox_topology_views',\n"
        src = src[:plugins_match.start(1)] + new_body + src[plugins_match.end(1):]
        print("[python] netbox_topology_views adicionado a PLUGINS")
    else:
        print("[python] netbox_topology_views ja estava em PLUGINS")

# 2) Garante PLUGINS_CONFIG['netbox_topology_views'] com defaults
NTV_CONFIG_BLOCK = textwrap.dedent("""\
    'netbox_topology_views': {
        # Doc: https://github.com/netbox-community/netbox-topology-views
        # Diretorio dos icones (dentro de STATIC_ROOT). A pasta e criada no Dockerfile-Plugins.
        'static_image_directory': 'netbox_topology_views/img',
        # Salva as coordenadas dos nos automaticamente quando voce arrasta.
        'allow_coordinates_saving': True,
        'always_save_coordinates': True,
    },
""")

# Acha o bloco PLUGINS_CONFIG = { ... } com matching de chaves balanceadas
pc_match = re.search(r"PLUGINS_CONFIG\s*=\s*\{", src)
if not pc_match:
    src += "\n\nPLUGINS_CONFIG = {\n" + textwrap.indent(NTV_CONFIG_BLOCK, "    ") + "}\n"
    print("[python] PLUGINS_CONFIG criado")
else:
    # Encontra a chave fechando '}' que pareia com a chave de abertura
    start = pc_match.end() - 1  # posicao do '{'
    depth = 0
    end = None
    for i in range(start, len(src)):
        if src[i] == '{':
            depth += 1
        elif src[i] == '}':
            depth -= 1
            if depth == 0:
                end = i
                break
    if end is None:
        print("[python] PLUGINS_CONFIG sem fechamento -- abortando para nao corromper o arquivo")
        sys.exit(1)

    pc_body = src[start+1:end]
    if "netbox_topology_views" in pc_body:
        print("[python] PLUGINS_CONFIG['netbox_topology_views'] ja existia, nao mexi")
    else:
        # insere logo apos a chave de abertura
        insert_at = start + 1
        src = src[:insert_at] + "\n" + textwrap.indent(NTV_CONFIG_BLOCK, "    ") + src[insert_at:]
        print("[python] PLUGINS_CONFIG['netbox_topology_views'] adicionado")

path.write_text(src, encoding="utf-8")
PYEOF

ok "configuration/plugins.py atualizado"

# ---------------------------------------------------------------------------
# 3) Dockerfile-Plugins: regenera com mkdir do img + migrate
# ---------------------------------------------------------------------------
log "Regenerando Dockerfile-Plugins..."

# Detecta se o plugin local (hide-empty-fields) esta presente, para preservar
# a sua linha de install.
INCLUDE_HEF_LINE=""
if [[ -d plugins/netbox_hide_empty_fields ]]; then
    INCLUDE_HEF_LINE=' /plugins/netbox_hide_empty_fields'
fi

cat > Dockerfile-Plugins <<DOCKERFILE_EOF
###############################################################################
# Dockerfile-Plugins  (gerado por install-netbox-topology-views.sh em ${TS})
#
# IMPORTANTE: NetBox 4.3+ removeu o binario \`pip\` do PATH; o gerenciador
# correto e \`uv pip\`. Refs:
#   https://github.com/netbox-community/netbox-docker/wiki/Using-Netbox-Plugins
#   https://github.com/netbox-community/netbox-docker/issues/1453
#
# Plugins instalados nesta imagem:
#   - netbox_hide_empty_fields (codigo local em /plugins, se presente)
#   - netbox-topology-views (PyPI)
###############################################################################

FROM netboxcommunity/netbox:latest

# Codigo dos plugins locais
COPY plugins /plugins
COPY plugin_requirements.txt /opt/netbox/

# Instala plugin local (se houver) e os pacotes do PyPI.
RUN /usr/local/bin/uv pip install --no-cache${INCLUDE_HEF_LINE} \\
 && /usr/local/bin/uv pip install --no-cache -r /opt/netbox/plugin_requirements.txt

# === netbox-topology-views: pasta dos icones de device ===
# O plugin serve as imagens a partir deste diretorio. Sem isso, os icones
# quebram. Doc: https://github.com/netbox-community/netbox-topology-views
RUN mkdir -p /opt/netbox/netbox/static/netbox_topology_views/img

# Configuracao do NetBox + registro dos plugins
COPY configuration/configuration.py /etc/netbox/config/configuration.py
COPY configuration/plugins.py /etc/netbox/config/plugins.py

# Coleta arquivos estaticos (CSS/JS/imagens) de TODOS os plugins.
# A flag --no-input evita prompt; SECRET_KEY dummy e usado apenas no build.
RUN DEBUG="true" SECRET_KEY="dummydummydummydummydummydummydummydummydummydummy" \\
    /opt/netbox/venv/bin/python /opt/netbox/netbox/manage.py collectstatic --no-input
DOCKERFILE_EOF

ok "Dockerfile-Plugins regenerado"

# ---------------------------------------------------------------------------
# 4) Sumario
# ---------------------------------------------------------------------------
echo
ok "Tudo pronto em $(pwd)."
echo
log "Resumo das mudancas:"
echo "  - plugin_requirements.txt:"
sed -n '/^[^#]/p' plugin_requirements.txt | sed 's|^|       |'
echo
echo "  - configuration/plugins.py (trecho PLUGINS):"
grep -n "netbox_" configuration/plugins.py | sed 's|^|       |'
echo
echo "  - Dockerfile-Plugins:"
echo "       (regenerado, incluindo mkdir de netbox_topology_views/img)"
echo

# ---------------------------------------------------------------------------
# 5) Build opcional
# ---------------------------------------------------------------------------
if [[ "$DO_BUILD" == "1" ]]; then
    log "Iniciando docker compose build --no-cache (pode demorar alguns minutos)..."
    docker compose build --no-cache
    log "Subindo containers..."
    docker compose up -d

    echo
    log "Aguardando o NetBox subir (migrate roda automaticamente no entrypoint)..."
    sleep 15
    echo
    log "Logs recentes do container netbox:"
    docker compose logs --tail=30 netbox || true
    echo
    ok "Pronto! Acesse o NetBox e va em Plugins > Topology Views."
else
    cat <<'NEXT_EOF'

==============================================================================
PROXIMOS PASSOS
==============================================================================
Execute (a partir desta pasta):

   docker compose build --no-cache
   docker compose up -d

Apos subir, acesse o NetBox e va em:
   Menu superior > Plugins > "Topology Views"

OBSERVACOES IMPORTANTES:
* O `migrate netbox_topology_views` e executado automaticamente pelo
  entrypoint do netbox-docker na hora do up -- voce nao precisa rodar manualmente.
* Topology Views desenha topologia COM BASE NOS CABOS cadastrados em DCIM.
  Se voce ainda nao cadastrou cabos entre devices, o diagrama ficara vazio.
* Para incluir icones bonitos por tipo de device, cadastre uma tag em DCIM
  com nome igual ao nome de imagem (ex.: "router"). Veja a doc do plugin:
  https://github.com/netbox-community/netbox-topology-views

==============================================================================
NEXT_EOF
fi
