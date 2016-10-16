from django.conf.urls import include, url
from hello_world import views as hello_world_views

from django.contrib import admin
admin.autodiscover()

urlpatterns = [
    url(r'^admin/', include(admin.site.urls)),
    url(r'^$', hello_world_views.hello_world, name='hello_world'),
]
