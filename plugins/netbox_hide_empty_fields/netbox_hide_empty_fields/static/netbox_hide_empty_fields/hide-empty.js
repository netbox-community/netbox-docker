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
