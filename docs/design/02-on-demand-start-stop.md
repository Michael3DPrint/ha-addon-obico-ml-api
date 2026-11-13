# 02 – Start the ML server only while a print is running

## Goal
The add-on is stopped normally (saves RAM/CPU). It starts when any selected printer begins a print
and stops when no selected printer is printing any more.

## Decisions (and why)
| # | Decision | Why |
|---|----------|-----|
| 1 | Control lives in **HA**, as an automation **blueprint** shipped in this repo (`blueprints/obico_ml_on_demand.yaml`). The add-on itself is unchanged apart from `boot: manual`. | An add-on cannot (and should not) know about printers or hold Supervisor/printer credentials. HA already has both the printer state and the `hassio.addon_start/stop` services. |
| 2 | `boot: manual` in `config.yaml`. | Otherwise HA OS starts it at boot even when nothing is printing. |
| 3 | Blueprint inputs: list of printer "print status" entities, the list of states that count as printing (default `running`, `pause`, `prepare`), the add-on (HA `addon` selector), stop delay (default 3 min), start delay. | No hard-coded entity names; works with several printers; pausing keeps the server up. |
| 4 | One automation, two triggers: any printer entity changes, and HA start. Logic = "is ANY selected printer active?" yes -> start (if not running), no -> wait stop-delay, re-check, then stop. | Handles several printers, HA restarts and flapping states (finish -> next job). |
| 5 | Stop only after the printer has been inactive for the full delay. | A job chain or brief state blip must not kill detection mid-print. |
| 6 | Cold start takes time (model load). Bambuddy/Obico calls in the first seconds may fail. Blueprint waits for `/hc/` is **not** possible without the add-on's IP, so a fixed start delay is not applied to anything; instead the user keeps detection triggered a bit after the print starts (e.g. first layer). | Keeps the blueprint simple; documented as a limitation. |

## Flowchart
```
 printer state changes  /  HA starts
        |
        v
 any selected printer in an "active" state?
   |yes                              |no
   v                                 v
 add-on running? --no--> hassio.addon_start     wait <stop delay>
   |yes -> nothing                      |
                                         v
                         still no printer active?  --no--> do nothing (a print began)
                                         |yes
                                         v
                          add-on running? --yes--> hassio.addon_stop
                                         |no -> nothing
 Error paths: printer entity "unavailable"/"unknown" counts as NOT active only after the
 stop delay; start/stop service errors are logged in the automation trace (no retry loop).
```

## Wireframe (blueprint form in HA)
```
 Obico ML on demand
 Printers' status entities  [ sensor.x2d_print_status ] [+ add]
 States that mean printing  [ running ] [ pause ] [ prepare ]
 Obico ML API add-on        [ Obico ML API v ]
 Stop delay (minutes)       [ 3 ]
 [Save]
```

## Data flow
```
 Bambu printer -> HA Bambu integration -> state entity -> HA automation
 HA automation -> hassio.addon_start / addon_stop -> Supervisor -> Obico ML API add-on
 (no printer credentials, no tokens in the blueprint; Bambuddy keeps calling :3333 as before)
```

## Risks
- Add-on watchdog: HA should not restart a deliberately stopped add-on, but this is **unverified**.
- Entity states differ per integration; defaults (`running`, `pause`, `prepare`) are from memory of the
  greghesp Bambu integration and **not checked** against your printer.
- Detection calls during the cold start window fail (see decision 6).
- Turning `boot` to manual means a manual start is needed after you disable the automation.

## Test plan
1. Static check: blueprint YAML parses; `scripts/check.sh` extended to check blueprint inputs/fields.
2. No live test by me (rule: I do not control your HA). You import the blueprint, start a print, and
   watch the automation trace; I read logs/traces you paste.

## Open questions
- Which entity shows print state for your printers (name and its states)?
- Does Bambuddy need the server to answer immediately at print start, or is a delay after start fine?

---
## Amendment A (decided during build, 2026-11-13)
- User confirmed a delay after print start is fine, so decision 6 stands: no readiness wait.
- The "is the add-on running?" check in the flowchart is **dropped**: a blueprint cannot map an add-on
  slug to its running sensor. `hassio.addon_start/stop` are called directly with `continue_on_error: true`;
  an error from starting an already-running add-on (behaviour unverified) is ignored.
- `mode: restart`: a new printer event cancels a pending stop wait and re-evaluates.
- Printer entity `unavailable`/`unknown` counts as not printing; it only stops the add-on if it stays that way for the full delay.
