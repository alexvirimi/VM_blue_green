#!/usr/bin/env bash
set -euo pipefail

IMAGE="${IMAGE:-vmbluegreen}"
NAME="${NAME:-vmbluegreen}"
PORT="${PORT:-8080}"
RETRIES="${RETRIES:-20}"            # espera máxima de 2s
STATE_FILE="${STATE_FILE:-.switch_state}"

log() { printf '[switch] %s\n' "$*"; }
die() { log "ERROR: $*" >&2; exit 1; }

running_tag() {
  docker inspect -f '{{.Config.Image}}' "$NAME" 2>/dev/null | sed 's/.*://' || true
}

wait_healthy() {  # nombre del contenedor $1
  local i status
  for ((i = 1; i <= RETRIES; i++)); do
    status=$(docker inspect -f '{{if .State.Running}}{{.State.Health.Status}}{{else}}exited{{end}}' "$1" 2>/dev/null || echo missing)
    case "$status" in
      healthy) return 0 ;;
      exited|missing) return 1 ;;
    esac
    sleep 2
  done
  return 1
}

preflight() {  # arranca un candidato aislado (sin puertos) y valida su /health
  local tag=$1 cand="${NAME}-candidate"
  docker rm -f "$cand" >/dev/null 2>&1 || true
  docker run -d --name "$cand" "$IMAGE:$tag" >/dev/null
  if wait_healthy "$cand"; then
    docker rm -f "$cand" >/dev/null; return 0
  fi
  docker logs --tail 20 "$cand" >&2 || true
  docker rm -f "$cand" >/dev/null
  return 1
}

start_release() {  # reemplaza el contenedor activo por IMAGE:$1
  local tag=$1
  docker rm -f "$NAME" >/dev/null 2>&1 || true
  docker run -d --name "$NAME" --restart unless-stopped -p "$PORT:8080" "$IMAGE:$tag" >/dev/null
  wait_healthy "$NAME"
}

save_state() { printf 'CURRENT=%s\nPREVIOUS=%s\n' "$1" "$2" > "$STATE_FILE"; }

deploy() {
  local tag=${1:-$(git rev-parse --short HEAD)}
  [[ -z ${1:-} ]] && [[ -n $(git status --porcelain) ]] && tag="${tag}-dirty"
  local prev; prev=$(running_tag)

  if ! docker image inspect "$IMAGE:$tag" >/dev/null 2>&1; then
    log "construyendo $IMAGE:$tag"
    docker build --build-arg GIT_SHA="$tag" -t "$IMAGE:$tag" .
  fi

  log "preflight de $tag"
  preflight "$tag" || die "el candidato $tag no pasó el healthcheck; no se tocó producción"

  log "cambiando ${prev:-<nada>} -> $tag"
  if start_release "$tag"; then
    save_state "$tag" "$prev"
    log "OK: sirviendo $tag (previa: ${prev:-ninguna})"
    return 0
  fi

  log "FALLÓ $tag tras el cambio"
  if [[ -n $prev ]]; then
    log "rollback automático a $prev"
    start_release "$prev" && die "rollback a $prev completado; $tag descartado" \
      || die "rollback a $prev también falló: intervención manual"
  fi
  die "sin versión previa a la que volver"
}

rollback() {
  [[ -f $STATE_FILE ]] || die "sin estado ($STATE_FILE)"
  # shellcheck disable=SC1090
  source "$STATE_FILE"
  [[ -n ${PREVIOUS:-} ]] || die "no hay versión previa registrada"
  docker image inspect "$IMAGE:$PREVIOUS" >/dev/null 2>&1 || die "la imagen $IMAGE:$PREVIOUS ya no existe"
  log "rollback $CURRENT -> $PREVIOUS"
  start_release "$PREVIOUS" || die "$PREVIOUS no arrancó sano"
  save_state "$PREVIOUS" "$CURRENT"
  log "OK: sirviendo $PREVIOUS"
}

status() {
  log "activa: $(running_tag || true)"
  [[ -f $STATE_FILE ]] && cat "$STATE_FILE" || true
  curl -fsS "http://127.0.0.1:$PORT/health" 2>/dev/null && echo || true
}

case "${1:-}" in
  deploy)   shift; deploy "$@" ;;
  rollback) rollback ;;
  status)   status ;;
  *) echo "Uso: $0 {deploy [tag]|rollback|status}" >&2; exit 2 ;;
esac
