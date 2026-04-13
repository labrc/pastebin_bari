FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    git \
    cron \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Create supervisor config to run gunicorn and cron
RUN mkdir -p /etc/supervisor/conf.d
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create auto-update script inside container
COPY docker_update.sh /app/docker_update.sh
RUN chmod +x /app/docker_update.sh

# Setup cron to run update script daily at midnight
RUN echo "0 0 * * * /app/docker_update.sh >> /var/log/pastebin_update.log 2>&1" > /etc/cron.d/pastebin-update \
    && chmod 0644 /etc/cron.d/pastebin-update \
    && crontab /etc/cron.d/pastebin-update

EXPOSE 8006

CMD ["supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]