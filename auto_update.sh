#!/bin/bash
###############################################################################
# Script de sincronización LOCAL -> GitHub
# Este script solo pushea cambios locales al repo
###############################################################################

PASTEBIN_DIR="/home/fcs2/Servidor/Pastebin"
LOG_FILE="/home/fcs2/Servidor/Pastebin/auto_update.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "========================================="
log "Sincronizando cambios locales a GitHub..."
log "========================================="

cd "$PASTEBIN_DIR"

if [[ -n "$(git status --porcelain)" ]]; then
    git add -A
    git commit -m "chore: sync $(date '+%Y-%m-%d %H:%M:%S')"
    git push origin main 2>&1 | tee -a "$LOG_FILE"
    log "Cambios locales pusheados."
else
    log "No hay cambios locales para pushear."
fi

log "========================================="
