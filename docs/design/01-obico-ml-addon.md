# 01 – Obico ML API as a Home Assistant OS add-on

## Goal
Run the **official** Obico `ml_api` (failure / spaghetti detection) as a local HA OS add-on, so HA
automations (or a self-hosted Obico server) can call `http://<ha-ip>:3333/p/?img=<url>`.
No third-party image, no third-party repo: everything is built from the official
`TheSpaghettiDetective/obico-server` source at a **pinned commit**.

## Decisions (and why)
| # | Decision | Why |
|---|----------|-----|
| 1 | Build from `ml_api/Containerfile.cpu` of the official repo (python:3.8-slim + onnxruntime CPU). | It is the official CPU-only recipe; small; no CUDA. The standard `ml_api/Dockerfile` uses a CUDA/darknet base meant for GPUs. |
| 2 | Add-on `Dockerfile` downloads the official source tarball at a pinned commit SHA and mirrors that recipe. | Reproducible; auditable; no author-owned image to trust. |
| 3 | Model weights (ONNX, ~200 MB) fetched at build time and checked against the SHA-256 that upstream ships. | Same integrity check upstream uses; add-on works offline afterwards. |
| 4 | Local add-on (`/addons/obico_ml_api/`), not a published repo. | You asked for your own; avoids creating/pushing any repo without your say-so. |
| 5 | Options: `ml_api_token` (password type). Empty = no auth (upstream behaviour), so the add-on **refuses to start without a token**. | Upstream `auth.py` silently disables auth if the token is unset; a safe default is better. |
| 6 | Port 3333/tcp exposed on the host; Watchdog on `http://[HOST]:[PORT:3333]/hc/`. | Upstream endpoints: `/p/` (predict), `/hc/` (health). |
| 7 | `arch: [amd64]` first. | Obico says the model is too slow on Pi-class CPUs. aarch64 left as an open item, not claimed. |
| 8 | gunicorn `--workers 1 --timeout 120`, as upstream. | Model loads at import; the default 30 s timeout loops on slow CPUs. |

## Wireframe (add-on Configuration tab)
```
 Obico ML API                              [Start] [Stop] [Restart]
 ------------------------------------------------------------------
 Info | Documentation | Configuration | Log
 ------------------------------------------------------------------
 ml_api_token  [ ************************ ]   (required, min 16 chars)
 Network:  3333/tcp  -> [ 3333 ]
 [x] Start on boot   [x] Watchdog   [ ] Auto update
 [Save]
```

## Flow (incl. error / empty paths)
```
 Start add-on
   |
   v
 token empty or < 16 chars? --yes--> log "set ml_api_token" -> exit 1 (HA shows stopped)
   |no
   v
 export ML_API_TOKEN -> gunicorn wsgi (loads ONNX model)
   |
   +-- model file missing/corrupt -> worker dies -> log error -> watchdog restarts (bounded by HA)
   v
 /hc/ answers 200 -> Watchdog green

 Request GET /p/?img=URL  (Authorization: Bearer <token>)
   |-- no/wrong token -> 401
   |-- img unreachable / bad -> 400 {detections: [], message}
   |-- deadline expired -> 503 {detections: []}
   '-- ok -> 200 {detections: [[label, conf, [x,y,w,h]], ...]}   (empty list = nothing found)
```

## Data flow
```
 HA camera / automation ---(img URL + Bearer token)---> add-on :3333 /p/
 add-on --(HTTP GET img URL, LAN only)--> printer camera snapshot
 add-on: OpenCV decode -> ONNX model -> detections JSON --> caller
 (no cloud calls, no image stored; SENTRY_DSN unset so no telemetry)
```

## Files to create
```
obico-ml-addon/
  obico_ml_api/            <- copy to /addons/obico_ml_api on HA OS
    config.yaml  Dockerfile  run.sh  DOCS.md  CHANGELOG.md
  scripts/check.sh          <- the project check command (lint + docker build + smoke test)
  docs/design/01-...md  docs/OPEN_ITEMS.md  docs/LEDGER.md
```

## Risks
- **AGPL-3.0** upstream: fine for private use; if you ever publish the add-on, publish source and keep the notice.
- Upstream drift: pinned SHA means no fixes until you bump it deliberately.
- Python 3.8 is end-of-life; this is upstream's own CPU recipe, kept as-is for fidelity.
- Build downloads ~200 MB model; build fails loudly on checksum mismatch.
- Nothing verified on real HA OS yet.

## Test plan
1. `scripts/check.sh`: shellcheck on `run.sh`, YAML validity of `config.yaml`, `docker build` for amd64.
2. Smoke test on this Mac in a local container: no token -> exits non-zero; token set -> `/hc/` 200;
   `/p/` without token 401; `/p/` with a sample image URL served by a local mock server -> JSON detections.
3. You then install it on HA OS (copy folder to `/addons`, reload store) and test — I do nothing on your HA.

## Open items to settle during build
- Pin commit SHA (read from `release` branch at build time).
- Confirm the arm64 question only if you run HA on ARM (which will probably be too slow).
- Docker must be available on this Mac for the smoke test (not yet checked).

---
## Amendment A (published repo, kept up to date)
Decision from the user: this becomes a **published GitHub repo**, maintained, unlike the third-party one.

| # | Change | Why |
|---|--------|-----|
| A1 | Repo is an HA *add-on repository*: `repository.yaml` at the root, add-on in `obico_ml_api/`. Users add the repo URL in the add-on store. | Standard HA layout. |
| A2 | `LICENSE` = AGPL-3.0 with an upstream notice (`NOTICE.md`) naming Obico and the pinned commit. | Our Dockerfile/scripts derive from AGPL files; publishing means complying. |
| A3 | Upstream tracking: a scheduled GitHub Action (weekly) checks the `release` branch of `obico-server`; if `ml_api/` changed it opens a PR bumping the pinned SHA. CI builds and smoke-tests the PR. A human (you) merges. | "Kept up to date" without silently shipping unreviewed upstream code. |
| A4 | CI on every PR: the same `scripts/check.sh` (shellcheck, YAML lint, HA add-on linter, docker build, smoke test). | Rule: check green before done, enforced by build. |
| A5 | Images: start with **build on the user's HA** (no registry, no credentials). Prebuilt images on GHCR are a later option. | Avoids registry tokens/secrets for now; slower first install (~200 MB model). |
| A6 | Docs: README with install steps, `docs/OPEN_ITEMS.md` and `docs/LEDGER.md` as the only status files. Nothing private (no IPs, tokens) in repo, fixtures or CI logs. | Your rules 5 and 6. |

### New risks
- Public repo: the pii-guard hook checks every commit/push; if it blocks something I fix the cause or tell you.
- Weekly job needs only the default `GITHUB_TOKEN` (no personal secrets).
- Upstream repo name/branch layout could change; the job fails loudly rather than guessing.

### To confirm before creating the repo (nothing created yet)
- Repo name, e.g. `ha-addon-obico-ml-api`.
- Visibility: public from the start, or private until you've tested it on HA OS (recommended).
- Commit identity: GitHub login `Michael3DPrint` and its no-reply address.
