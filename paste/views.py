from django.shortcuts import render, get_object_or_404
from django.http import JsonResponse
from django.views.decorators.http import require_http_methods
from django.views.decorators.csrf import csrf_exempt
from django.core.paginator import Paginator
import json
from .models import Paste

@require_http_methods(["GET"])
def index(request):
    """Página principal con formulario para pegar texto"""
    return render(request, 'paste/index.html')

@csrf_exempt
@require_http_methods(["POST"])
def create_paste(request):
    """Crear una nueva nota/paste"""
    try:
        data = json.loads(request.body)
        content = data.get('content', '').strip()
        
        if not content:
            return JsonResponse({'error': 'El contenido no puede estar vacío'}, status=400)
        
        paste = Paste.objects.create(content=content)
        
        return JsonResponse({
            'id': paste.id,
            'created_at': paste.created_at.isoformat(),
            'message': 'Nota guardada correctamente'
        }, status=201)
    except json.JSONDecodeError:
        return JsonResponse({'error': 'JSON inválido'}, status=400)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)

@require_http_methods(["GET"])
def notas_list(request):
    """Listado de todas las notas"""
    pastes = Paste.objects.all()
    
    # Paginación
    page_num = request.GET.get('page', 1)
    paginator = Paginator(pastes, 20)
    page_obj = paginator.get_page(page_num)
    
    context = {
        'page_obj': page_obj,
        'total_count': paginator.count,
    }
    
    return render(request, 'paste/notas_list.html', context)

@csrf_exempt
@require_http_methods(["GET"])
def get_paste(request, paste_id):
    """Obtener una nota específica en JSON"""
    paste = get_object_or_404(Paste, id=paste_id)
    
    return JsonResponse({
        'id': paste.id,
        'content': paste.content,
        'created_at': paste.created_at.isoformat(),
        'updated_at': paste.updated_at.isoformat(),
    })

@csrf_exempt
@require_http_methods(["DELETE"])
def delete_paste(request, paste_id):
    """Eliminar una nota"""
    paste = get_object_or_404(Paste, id=paste_id)
    paste_id = paste.id
    paste.delete()
    
    return JsonResponse({
        'message': f'Nota {paste_id} eliminada correctamente'
    })