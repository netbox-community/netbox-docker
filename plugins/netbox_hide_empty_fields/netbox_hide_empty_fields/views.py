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
