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
