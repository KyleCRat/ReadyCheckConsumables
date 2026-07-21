# Post-12.1.0 Cleanup

Use this checklist after the final 12.1.0 Retail export is verified and RCC no
longer supports 12.0.7.

- [ ] Remove Interface `120007` from `ReadyCheckConsumables.toc`, leaving only
  `120100`.
- [ ] Remove the macro-limit compatibility chain from
  `Modules/ConsumableMacros/ConsumableMacros.lua`:
  - remove `DEFAULT_MAX_ACCOUNT_MACROS` and `DEFAULT_MAX_CHARACTER_MACROS`;
  - remove the legacy `MAX_ACCOUNT_MACROS` and `MAX_CHARACTER_MACROS` fallbacks;
  - replace `getMacroLimits()` with direct locals from
    `Constants.MacroConsts`.
  - Confirm the final generated documentation defines both constants, then test
    shared and character-specific managed macros.
- [ ] Remove the `C_UnitAuras.GetAuraDataByAuraInstanceID` existence fallback
  from `F.GetCurrentPublicAuraInstanceID` after confirming the function remains
  in the final API. Remove only the availability check; keep `pcall` and the
  secret-value/access guards because 12.1 can restrict aura queries.
- [ ] Retire the legacy `"OIL"` temporary-weapon-enchant message type after the
  older-RCC compatibility window ends. This is an RCC protocol fallback, not a
  WoW client fallback; update the sender and receiver together and test status
  exchange between two current clients.

Final checks:

- [ ] Confirm Retail reports Interface `120100` and RCC loads without enabling
  out-of-date addons.
- [ ] Search for remaining `120007`, legacy macro-limit, and `"OIL"` references.
- [ ] Parse all Lua files and smoke-test ready checks, aura tooltips, and managed
  macros.
