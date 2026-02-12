local _, RCC = ...
RCC.db = RCC.db or {}

-------------------------------------------------------------------------------
--- Gem Item IDs (12.0.0 - Midnight)
--- Stored for future use. Not currently used by the addon.
--- Organized by gem color, then stat prefix.
--- Base gems are uncommon, Flawless gems are rare.
-------------------------------------------------------------------------------

RCC.db.gemItemIDs = {
    -- 12.0.0 - Midnight
    amethyst = {
        deadly    = { 240866, 240855 },
        masterful = { 240863 },
        quick     = { 240867, 240868 },
        versatile = { 240869, 240870 },
    },
    flawless_amethyst = {
        deadly    = { 240891, 240858 },
        masterful = { 240895, 240896 },
        quick     = { 240899, 240900 },
        versatile = { 240901, 240902 },
    },
    garnet = {
        deadly    = { 240871 },
        masterful = { 240876, 240875 },
        quick     = { 240873 },
        versatile = { 240877, 240879 },
    },
    flawless_garnet = {
        deadly    = { 240903, 240904 },
        masterful = { 240907, 240908 },
        quick     = { 240905, 240906 },
        versatile = { 240909, 240910 },
    },
    lapis = {
        deadly    = { 240881, 240882 },
        masterful = { 240885, 240886 },
        quick     = { 240883 },
        versatile = { 240880 },
    },
    flawless_lapis = {
        deadly    = { 240914, 240913 },
        masterful = { 240917, 240918 },
        quick     = { 240915, 240916 },
        versatile = { 240911, 240912 },
    },
    peridot = {
        deadly    = { 240857, 240862 },
        masterful = { 240859, 240860 },
        quick     = { 240856, 240865 },
        versatile = { 240861, 240864 },
    },
    flawless_peridot = {
        deadly    = { 240888, 240889 },
        masterful = { 240892, 240890 },
        quick     = { 240887, 240898 },
        versatile = { 240893, 240894 },
    },
    eversong_diamond = {
        indecipherable = { 240983, 240982 },
        powerful       = { 240966, 240967 },
        stoic          = { 240970, 240971 },
        telluric       = { 240968, 240969 },
    },
    heliotrope = {
        cognitive  = { 241143 },
        determined = { 241142 },
        enduring   = { 241144 },
    },
}
