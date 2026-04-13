#!/bin/bash
###############################################################################
# Script de actualización automática DENTRO del contenedor
# Se ejecuta todos los días a las 00:00 vía cron
###############################################################################

set -e

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ========================================="
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iniciando actualización automática..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] ========================================="

cd /app

# 1. Pull de actualizaciones de GitHub
echo "[$(date '+%Y-%m-%d %H:%M:%S')] >>> Buscando actualizaciones desde GitHub..."
git pull origin main 2>&1 || {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Error al hacer pull. Verificá la configuración de Git."
    exit 1
}

# Re-aplicar permisos al script (git pull puede resetearlos)
chmod +x /app/docker_update.sh 2>/dev/null || true

# 2. Verificar si hubo actualizaciones
CURRENT_HASH=$(git rev-parse HEAD)
PREV_HASH_FILE="/tmp/.last_commit_hash"

if [[ -f "$PREV_HASH_FILE" ]]; then
    OLD_HASH=$(cat "$PREV_HASH_FILE")
    if [[ "$CURRENT_HASH" != "$OLD_HASH" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Nuevos cambios detectados!"
        
        # 3. Ejecutar migraciones de Django
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] >>> Ejecutando migraciones..."
        python manage.py migrate --noinput 2>&1
        
        # 4. Recolectar archivos estáticos
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] >>> Recolectando archivos estáticos..."
        python manage.py collectstatic --noinput 2>&1
        
        # 5. Actualizar hash
        echo "$CURRENT_HASH" > "$PREV_HASH_FILE"
        
        # 6. Reiniciar gunicorn (enviar señal SIGHUP al proceso master)
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] >>> Reinyectando Gunicorn..."
        GUNICORN_PID=$(pgrep -f "gunicorn config.wsgi" | head -1)
        if [[ -n "$GUNICORN_PID" ]]; then
            kill -HUP $GUNICORN_PID 2>&1
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Gunicorn reinyectado (PID: $GUNICORN_PID)"
        fi
        
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Actualización completada con éxito."
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] No hay actualizaciones. Todo al día."
    fi
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Primera ejecución. Guardando hash inicial."
    echo "$CURRENT_HASH" > "$PREV_HASH_FILE"
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] ========================================="
