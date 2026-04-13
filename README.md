# 📝 Pastebin para bari.ar

Un pastebin rápido y minimalista construido con Django, con diseño moderno en Tailwind CSS, integrado con tu stack Docker existente.

## ✨ Características

- ✅ **Rápido**: Pegá, guardá y listo
- ✅ **Seguro**: HTTPS con Let's Encrypt + CrowdSec
- ✅ **Fecha automática**: Cada nota se guarda con marca de tiempo
- ✅ **Sin límite**: Guardá textos, código, configuraciones, lo que sea
- ✅ **Fácil de revisar**: Listado de todas las notas en `/notas`
- ✅ **Copiar y eliminar**: Acciones rápidas desde la interfaz
- ✅ **Responsive**: Funciona en móvil y desktop

## 📋 Requisitos

- Docker y Docker Compose
- Acceso a `/home/fcs2/Servidor/`
- Tu nginx-proxy ya configurado (como en el docker-compose existente)

## 🚀 Instalación

### 1️⃣ Crear estructura de directorios

```bash
sudo mkdir -p /home/$user/Servidor/Pastebin
cd /home/$user/Servidor/Pastebin
```

### 2️⃣ Copiar archivos

Copia todos los archivos generados a `/home/$user/Servidor/Pastebin/`:

```
Pastebin/
├── config/
│   ├── __init__.py
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
├── paste/
│   ├── __init__.py
│   ├── apps.py
│   ├── models.py
│   └── views.py
├── templates/
│   ├── base.html
│   └── paste/
│       ├── index.html
│       └── notas_list.html
├── manage.py
├── Dockerfile
├── requirements.txt
├── pastebin_nginx.conf
└── (staticfiles/ y media/ se crearán automáticamente)
```

### 3️⃣ Configurar permisos

```bash
sudo chown -R $user:$user /home/$user/Servidor/Pastebin
cd /home/$user/Servidor/Pastebin
chmod +x manage.py
```

### 4️⃣ Copiar configuración nginx

```bash
cp pastebin_nginx.conf /home/$user/Servidor/conf.d/
```

### 5️⃣ Agregar a docker-compose.yml

Abre tu `/home/$user/Wanderer/Web2/docker-compose.yml` y **ANTES** de la última sección `networks:`, 
agrega el fragmento que está en `docker-compose-fragment.yml`.

Debería verse así:

```yaml
# ... otros servicios ...

  ###################################################
  # PASTEBIN - NOTAS RÁPIDAS
  ###################################################
  django_pastebin:
    build: /home/fcs2/Servidor/Pastebin
    restart: always
    working_dir: /app
    volumes:
      - /home/fcs2/Servidor/Pastebin:/app
    expose:
      - "8006"
    command: >
      sh -c "python manage.py migrate &&
             python manage.py collectstatic --noinput &&
             gunicorn config.wsgi:application --bind 0.0.0.0:8006"
    networks:
      - nginx-proxy-network

  nginx_pastebin:
    image: nginx:alpine
    container_name: nginx_pastebin
    restart: always
    depends_on:
      - django_pastebin
    expose:
      - "80"
    volumes:
      - /home/fcs2/Servidor/Pastebin/staticfiles:/app/staticfiles:ro
      - /home/fcs2/Servidor/Pastebin/media:/app/media:ro
      - /home/fcs2/Servidor/conf.d/pastebin_nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - /home/fcs2/Servidor/conf.d/proxy_params:/etc/nginx/proxy_params:ro
      - logs_nginx:/var/log/nginx
    environment:
      - VIRTUAL_HOST=paste.bari.ar
      - LETSENCRYPT_HOST=paste.bari.ar
      - LETSENCRYPT_EMAIL=lautaro@tutamail.com
      - CROWDSEC_BOUNCER_API_URL=http://crowdsec:8080
    networks:
      - nginx-proxy-network

###################################################
  # RED COMPARTIDA
  ###################################################
networks:
  nginx-proxy-network:
    external: true
```

### 6️⃣ Iniciar los contenedores

```bash
docker-compose up -d
```

Verifica que se inició correctamente:

```bash
docker-compose logs -f django_pastebin
docker-compose logs -f nginx_pastebin
```

### 7️⃣ Acceder a la aplicación

## 📖 Uso

### Crear una nota

1. Accedé a la web
2. Pegá tu contenido en el textarea
3. Click en "Guardar Nota"
4. ¡Automáticamente se guarda con fecha y hora!

### Ver todas las notas

Accedé a `/notas/` para ver un listado de todas las notas guardadas.

Características del listado:
- 📅 Fecha y hora de creación
- 👁️ Preview de la primera línea
- 📋 Botón para copiar al portapapeles
- 🗑️ Botón para eliminar la nota
- 👉 Click en una nota para expandir el contenido

## 🔧 Configuración

### Cambiar el email de Let's Encrypt

En `docker-compose-fragment.yml`, busca `LETSENCRYPT_EMAIL` y cámbialo:

```yaml
LETSENCRYPT_EMAIL=tu-email@ejemplo.com
```

### Aumentar límite de carga

En `pastebin_nginx.conf`:

```nginx
client_max_body_size 50M;  # Cambiar a lo que necesites
```

### Cambiar la clave secreta de Django

En `config/settings.py`:

```python
SECRET_KEY = 'tu-clave-secreta-super-segura-aqui'
```

## 🗄️ Base de datos

La aplicación usa SQLite por defecto, que se guarda en:
```
/home/fcs2/Servidor/Pastebin/db.sqlite3
```

Para hacer un backup:
```bash
cp /home/$user/Servidor/Pastebin/db.sqlite3 /home/$user/Servidor/Pastebin/db.sqlite3.backup
```

## 📊 Monitoreo

Ver logs en vivo:
```bash
docker-compose logs -f django_pastebin
```

Ver logs de nginx:
```bash
docker-compose logs -f nginx_pastebin
```

## 🛡️ Seguridad

- ✅ HTTPS con certificados Let's Encrypt
- ✅ Integración con CrowdSec para protección contra ataques
- ✅ CSRF protection habilitado
- ✅ Security headers configurados
- ✅ SQLite con permisos restrictivos

## 🐛 Troubleshooting

### Error: "Port 8006 is already in use"

Cambia el puerto en `docker-compose-fragment.yml`:
```yaml
expose:
  - "8007"  # O el puerto que prefieras
```

Y en `pastebin_nginx.conf`:
```nginx
server django_pastebin:8007;
```

### La base de datos está corrupta

```bash
docker-compose down
rm /home/$user/Servidor/Pastebin/db.sqlite3
docker-compose up -d
```

### No funciona el SSL

Espera un par de minutos a que Let's Encrypt genere el certificado.
Verifica los logs:
```bash
docker-compose logs letsencrypt
```

## 📝 Estructura del proyecto

```
Pastebin/
├── config/                 # Configuración Django
│   ├── __init__.py
│   ├── settings.py        # Configuración principal
│   ├── urls.py            # Rutas de la aplicación
│   └── wsgi.py            # WSGI para Gunicorn
├── paste/                 # App principal
│   ├── __init__.py
│   ├── apps.py
│   ├── models.py          # Modelo de Paste
│   └── views.py           # Vistas/APIs
├── templates/             # Templates HTML
│   ├── base.html          # Base con Tailwind
│   └── paste/
│       ├── index.html     # Formulario principal
│       └── notas_list.html # Listado de notas
├── manage.py              # CLI de Django
├── Dockerfile             # Para Docker
├── requirements.txt       # Dependencias Python
└── pastebin_nginx.conf    # Config nginx

```

## 🚀 Mejoras futuras

- [ ] Autenticación opcional
- [ ] Expiración automática de notas
- [ ] Export a JSON/PDF
- [ ] Busqueda/filtrado
- [ ] Destacado de sintaxis para código
- [ ] Compartir notas

## 📄 Licencia

Libre para usar y modificar. ¡Disfrutá! 🎉

---

**¿Preguntas?** Revisá los logs o contactá al admin.
