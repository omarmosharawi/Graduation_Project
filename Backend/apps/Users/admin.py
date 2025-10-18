from django.contrib import admin
from unfold.admin import ModelAdmin
from .models import User

# Register your models here.


# admin.site.register(User)


@admin.register(User)
class CustomAdminClass(ModelAdmin):
    pass