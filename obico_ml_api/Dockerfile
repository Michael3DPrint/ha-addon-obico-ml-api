# Mirrors the official ml_api/Containerfile.cpu of TheSpaghettiDetective/obico-server,
# built from the source at one pinned commit. Bump OBICO_SHA deliberately (see docs/).
FROM python:3.8-slim

ARG OBICO_SHA=df8190ef7500459599ebf398c3d1f653754792fd

RUN apt-get update \
    && apt-get install --no-install-recommends --assume-yes \
        curl ca-certificates libgomp1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir onnxruntime==1.16.3 opencv-python-headless==4.12.0.88

# Official ml_api source at the pinned commit (AGPL-3.0, see NOTICE.md).
RUN curl -fsSL "https://github.com/TheSpaghettiDetective/obico-server/archive/${OBICO_SHA}.tar.gz" \
      | tar -xz --strip-components=2 -C /app "obico-server-${OBICO_SHA}/ml_api" \
    && pip install --no-cache-dir --requirement requirements.txt \
    && install -m 0755 scripts/fetch_verified.sh /usr/local/bin/fetch_verified

# ONNX weights, verified against the checksum shipped upstream.
RUN mkdir -p /model_cache/ml_api/onnx \
    && fetch_verified "$(tr -d '\r' < model/model-weights.onnx.url)" \
        /model_cache/ml_api/onnx/model-weights.onnx 50000000 \
        "$(tr -d '\r' < model/model-weights.onnx.sha256)"

COPY run.sh /run.sh
RUN chmod +x /run.sh
EXPOSE 3333
CMD ["/run.sh"]
