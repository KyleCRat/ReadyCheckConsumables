# Post-12.1.0 Cleanup

Use this checklist after the final 12.1.0 Retail export is verified and RCC no
longer supports 12.0.7.

- [ ] Retire the legacy `"OIL"` temporary-weapon-enchant message type after the
  older-RCC compatibility window ends. This is an RCC protocol fallback, not a
  WoW client fallback; update the sender and receiver together and test status
  exchange between two current clients.

Final checks:

- [ ] Smoke-test ready checks, aura tooltips, and managed macros in game.
