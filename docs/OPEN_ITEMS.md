# Open items
- [ ] Test the add-on on a real HA OS (nothing verified there yet)
- [ ] Confirm `ml_api_token: ""` default plus `password(16,)` schema behaves in the HA UI
- [ ] Decide on prebuilt GHCR images (needs registry credentials)
- [ ] arm64 support (unclaimed; likely too slow)
- [ ] Verify blueprint on a real HA: default states (`running`/`pause`/`prepare`) match the printer entity
- [ ] Verify HA watchdog does not restart the add-on after the blueprint stops it
- [ ] Verify start of an already running add-on is harmless (errors are ignored)
