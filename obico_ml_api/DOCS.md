# Obico ML API

1. Install and set `ml_api_token` (16+ characters), then start the add-on.
2. Health check: `http://<HA-IP>:3333/hc/`
3. Predict: `GET http://<HA-IP>:3333/p/?img=<snapshot-url>` with header `Authorization: Bearer <token>`.

Response: `{"detections": [[label, confidence, [x, y, w, h]], ...]}`; an empty list means nothing found.
The first build downloads about 200 MB of model weights.
