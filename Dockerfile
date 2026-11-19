# syntax=docker/dockerfile:1
FROM python:3.12-slim AS base

# Keep Python from writing .pyc files / buffering stdout (so `docker logs` is live)
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install deps first so code edits don't bust the layer cache
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Non-root user for container isolation
RUN apt-get update && apt-get install -y --no-install-recommends sqlite3 && rm -rf /var/lib/apt/lists/*
RUN useradd --create-home --uid 10001 --shell /usr/sbin/nologin botuser \
    && mkdir -p /app/data \
    && chown -R botuser:botuser /app

COPY --chown=botuser:botuser app.py scrapers.py ./

USER botuser

# Matches HEALTHCHECK_FILE in .env — flags a stuck container (e.g. deadlocked scheduler)
HEALTHCHECK --interval=5m --timeout=10s --start-period=2m --retries=3 \
    CMD find /app/data/heartbeat.txt -mmin -15 | grep -q . || exit 1

ENTRYPOINT ["python", "-u", "app.py"]
