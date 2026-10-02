# syntax=docker/dockerfile:1

# ============================================
# Stage 1: builder — installs dependencies from pyproject.toml
# ============================================

FROM python:3.13-slim AS builder

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY pyproject.toml ./
COPY app ./app

RUN python -m venv /opt/venv \
    && /opt/venv/bin/pip install --upgrade pip \
    && /opt/venv/bin/pip install .

# ============================================
# Stage 2: runtime — API and plain Celery workers
# ============================================

FROM python:3.13-slim AS runtime

# Match the host user so bind-mounted files stay writable.
ARG UID=1000
ARG GID=1000

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid "${GID}" app \
    && useradd --uid "${UID}" --gid "${GID}" --create-home app

ENV PATH="/opt/venv/bin:${PATH}" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

COPY --from=builder /opt/venv /opt/venv

WORKDIR /app
COPY --chown=${UID}:${GID} . .

USER app

EXPOSE 8000

# Overridden per compose service (uvicorn, celery worker, celery beat).
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

# ============================================
# Stage 3: browser — worker-browser with Playwright
# ============================================

ARG PLAYWRIGHT_IMAGE=mcr.microsoft.com/playwright/python:v1.49.0-jammy
FROM ${PLAYWRIGHT_IMAGE} AS browser

ARG UID=1000
ARG GID=1000

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

COPY pyproject.toml ./
COPY app ./app

RUN pip install --upgrade pip \
    && pip install . \
    && groupadd --gid "${GID}" app \
    && useradd --uid "${UID}" --gid "${GID}" --create-home app \
    && chown -R "${UID}:${GID}" /app

COPY --chown=${UID}:${GID} . .

USER app

CMD ["celery", "-A", "app.worker", "worker", "-Q", "browser", "--concurrency=2"]
