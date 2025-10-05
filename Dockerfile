# Dockerfile
FROM postgres:16

# Устанавливаем pgTAP. В одних репах пакет называется postgresql-16-pgtap,
# в других — просто pgtap. Пробуем по очереди.
RUN set -eux; \
    apt-get update; \
    if apt-get install -y --no-install-recommends postgresql-16-pgtap; then \
      true; \
    else \
      apt-get install -y --no-install-recommends pgtap; \
    fi; \
    rm -rf /var/lib/apt/lists/*
