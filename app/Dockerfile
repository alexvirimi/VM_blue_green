FROM python:3.12-slim

LABEL maintainer="Firmes por palmer" \
      description="App Green or Blue"

# GIT_SHA para identificar commits
ARG GIT_SHA=dev
ENV APP_VERSION=${GIT_SHA} \
    PYTHONUNBUFFERED=1
LABEL org.opencontainers.image.revision=${GIT_SHA}

# Usuario sin privilegios (UID fijo)
RUN groupadd --system --gid 10001 app \
 && useradd  --system --uid 10001 --gid app --no-create-home --shell /usr/sbin/nologin app

WORKDIR /app
COPY --chown=10001:10001 app.py .

USER 10001:10001
EXPOSE 8080

HEALTHCHECK --interval=2s --timeout=2s --start-period=2s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/health', timeout=2)" || exit 1

CMD ["python", "app.py"]
