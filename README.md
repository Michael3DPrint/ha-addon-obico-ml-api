# Obico ML API – Home Assistant OS add-on

Runs the **official** Obico `ml_api` (print failure / spaghetti detection) as an HA OS add-on, built
from upstream source at a pinned commit. CPU only, amd64 only (Obico says Raspberry Pi CPUs are too weak).

## Install
Settings → Add-ons → Add-on Store → ⋮ → Repositories → add
`https://github.com/Michael3DPrint/ha-addon-obico-ml-api`, install **Obico ML API**, set `ml_api_token`
(16+ characters), start. See `obico_ml_api/DOCS.md` for the API.

## Stays current
A weekly workflow opens a PR when upstream `ml_api/` changes; CI builds it, a human merges.
Status: `docs/OPEN_ITEMS.md` and `docs/LEDGER.md`. Design: `docs/design/`.

Not affiliated with Obico. AGPL-3.0, see `NOTICE.md`.
