local _, RCC = ...

local Recuperate = {}
RCC.Consumables.Recuperate = Recuperate

Recuperate.Dependencies = {}

function Recuperate.Select()
    return {
        icon = RCC.db.recuperateIconID,
        action = RCC.ConsumableState.CreateSpellAction(
            RCC.db.recuperateSpellID,
            { available = true }
        ),
    }
end
