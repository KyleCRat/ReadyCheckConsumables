# LibPopupSlider-1.0

A vertical drag-to-adjust slider popup for WoW addons. Click-and-drag on a button opens a slider at the cursor; release to dismiss.

## Usage

```lua
local LibPopupSlider = LibStub("LibPopupSlider-1.0")

local popup = LibPopupSlider:Create(myButton, {
    minValue       = 50,
    maxValue       = 150,
    step           = 5,
    label          = "Scale",
    formatValue    = function(v) return v .. "%" end,
    onValueChanged = function(v)
        myFrame:SetScale(v / 100)
    end,
})

-- Set initial value
popup:SetValue(100)

-- Read current value
local current = popup:GetValue()
```

## Options

| Option | Default | Description |
|---|---|---|
| `minValue` | `0` | Minimum value |
| `maxValue` | `100` | Maximum value |
| `step` | `1` | Snap increment |
| `label` | `""` | Label above the slider |
| `formatValue` | `tostring` | Format the value display |
| `onValueChanged` | `nil` | Callback on value change |
| `sliderHeight` | `180` | Track height in pixels |
| `sensitivity` | `1` | Cursor-to-thumb ratio (1 = 1:1) |
| `popupWidth` | `44` | Popup frame width |
| `paddingY` | `20` | Vertical padding inside popup |
| `labelGap` | `4` | Gap between labels and slider |
| `font` | `FRIZQT__.TTF` | Font for labels |
| `bgColor` | dark gray | `{ r, g, b, a }` background |
| `trackColor` | mid gray | `{ r, g, b, a }` track and diamonds |

## Implementation Notes

**Vertical slider art** — WoW's `MinimalSliderTemplate` is horizontal-only; its track textures don't rotate. This library uses a bare `Slider` frame with a custom track line and the `Minimal_SliderBar_Button` atlas for the thumb.

**Value inversion** — WoW vertical sliders map min=top, max=bottom. The library inverts internally so higher values correspond to dragging up.

**Absolute drag tracking** — The drag delta is computed from the original mousedown position, not incrementally per frame. This prevents compounding rounding error when step-snapping, which would otherwise make the thumb drift ahead of the cursor.

**Boundary reset** — When the cursor overshoots past min/max, the drag origin resets so reversing direction responds immediately with no dead zone.

**Thumb-aligned positioning** — The popup positions itself so the thumb (at its current value) appears directly under the cursor on open.

**Screen clamping** — The popup is clamped to UIParent bounds so it never opens off-screen.
