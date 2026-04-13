from django.urls import path
from paste import views

urlpatterns = [
    path('', views.index, name='index'),
    path('api/paste/', views.create_paste, name='create_paste'),
    path('notas/', views.notas_list, name='notas_list'),
    path('api/paste/<int:paste_id>/', views.get_paste, name='get_paste'),
    path('api/paste/<int:paste_id>/delete/', views.delete_paste, name='delete_paste'),
]