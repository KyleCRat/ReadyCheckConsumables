local _, RCC = ...

RCC.color = "cff00cc"
RCC.db = RCC.db or {}

-- C_UnitAuras has no count API; nil marks the end of the aura list.
RCC.MAX_AURAS = 255
