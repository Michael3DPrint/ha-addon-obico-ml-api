# Obico ML API – Home Assistant OS add-on

Runs the **official** Obico `ml_api` (print failure / spaghetti detection) as an HA OS add-on, built
from upstream source at a pinned commit. CPU only, amd64 only (Obico says Raspberry Pi CPUs are too weak).

## Install
Settings → Add-ons → Add-on Store → ⋮ → Repositories → add
`https://github.com/Michael3DPrint/ha-addon-obico-ml-api`, install **Obico ML API**, set `ml_api_token`
(16+ characters), start. See `obico_ml_api/DOCS.md` for the API.

## Start only while printing (optional)
The add-on is set to manual start. Import the blueprint, pick your printers' print-status entities
and this add-on; it starts the server when a print begins and stops it after all printers have been
idle for the stop delay (default 3 min):
[![Import blueprint](https://my.home-assistant.io/badges/blueprint_import.svg)](https://my.home-assistant.io/redirect/blueprint_import/?blueprint_url=https%3A%2F%2Fgithub.com%2FMichael3DPrint%2Fha-addon-obico-ml-api%2Fblob%2Fmain%2Fblueprints%2Fobico_ml_on_demand.yaml)
Needs HA 2024.10+. The first seconds after a start fail while the model loads. Details: `docs/design/02-on-demand-start-stop.md`.

## Stays current
A weekly workflow opens a PR when upstream `ml_api/` changes; CI builds it, a human merges.
Status: `docs/OPEN_ITEMS.md` and `docs/LEDGER.md`. Design: `docs/design/`.

Not affiliated with Obico. AGPL-3.0, see `NOTICE.md`.
