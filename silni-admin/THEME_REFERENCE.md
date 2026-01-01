# Silni Theme Color Reference

This document provides the HEX values for all built-in themes. Use these as reference when creating new themes in the admin panel.

---

## Color Categories

### Main Colors (Required)
| Key | Description | Used For |
|-----|-------------|----------|
| `primary` | Main brand color | Buttons, active states, primary UI elements |
| `primary_light` | Lighter variant | Hover states, highlights |
| `primary_dark` | Darker variant | Pressed states, shadows |
| `secondary` | Secondary brand color | Accents, badges, secondary buttons |
| `accent` | Accent/highlight color | CTAs, important elements, notifications |

### Background Colors (Required)
| Key | Description | Used For |
|-----|-------------|----------|
| `background_1` | Darkest background | Top of gradient, headers |
| `background_2` | Middle background | Main content area |
| `background_3` | Lightest background | Bottom of gradient, footers |
| `surface` | Surface/card base | Cards, dialogs, sheets |
| `surface_variant` | Alternative surface | Secondary cards, nested containers |

### Text Colors
| Key | Description | Used For |
|-----|-------------|----------|
| `text_primary` | Main text color | Headlines, body text |
| `text_secondary` | Secondary text | Subtitles, descriptions |
| `text_hint` | Hint/placeholder text | Placeholders, disabled text |
| `text_on_gradient` | Text on gradients | Text overlaying gradient backgrounds |
| `on_primary` | Text on primary color | Button text, icons on primary |
| `on_secondary` | Text on secondary color | Text on secondary backgrounds |
| `on_surface` | Text on surfaces | Card text, dialog text |
| `on_surface_variant` | Text on surface variant | Secondary card text |

### Glass Effect Colors
| Key | Description | Used For |
|-----|-------------|----------|
| `glass_background` | Glass card background | Semi-transparent card backgrounds |
| `glass_border` | Glass card border | Semi-transparent borders |
| `glass_highlight` | Glass highlight | Glowing/highlight effects |
| `card_background` | Card background | Standard card backgrounds |
| `card_border` | Card border | Card borders |

### Utility Colors
| Key | Description | Used For |
|-----|-------------|----------|
| `shimmer_base` | Shimmer loading base | Loading skeleton base color |
| `shimmer_highlight` | Shimmer loading highlight | Loading skeleton highlight |
| `divider` | Divider lines | Separators, list dividers |
| `disabled` | Disabled state | Disabled buttons, inactive elements |

---

## Gradient Auto-Generation

If you don't define gradients explicitly, they are auto-generated from flat colors:

| Gradient Key | Auto-Generated From |
|--------------|---------------------|
| `primary` | `[primary_dark, primary, primary_light]` |
| `background` | `[background_1, background_2, background_3]` |
| `golden` | `[accent, secondary]` |
| `streak_fire` | `[primary_dark, primary, accent]` |

---

## Built-in Theme Reference

### 1. Silni Green (Default) - `default`
```json
{
  "colors": {
    "primary": "#2E7D32",
    "primary_light": "#60AD5E",
    "primary_dark": "#005005",
    "secondary": "#FFD700",
    "accent": "#FF6F00",
    "background_1": "#1B5E20",
    "background_2": "#2E7D32",
    "background_3": "#388E3C",
    "on_primary": "#FFFFFF",
    "on_secondary": "#1B5E20",
    "surface": "#1B5E20",
    "on_surface": "#FFFFFF",
    "surface_variant": "#2E7D32",
    "on_surface_variant": "#E8F5E9",
    "glass_background": "#FFFFFF26",
    "glass_border": "#FFFFFF33",
    "glass_highlight": "#FFFFFF4D",
    "text_primary": "#FFFFFF",
    "text_secondary": "#FFFFFFB3",
    "text_hint": "#FFFFFF80",
    "text_on_gradient": "#FFFFFF",
    "shimmer_base": "#2E7D32",
    "shimmer_highlight": "#81C784",
    "card_background": "#FFFFFF26",
    "card_border": "#FFFFFF33",
    "divider": "#FFFFFF33",
    "disabled": "#FFFFFF80"
  },
  "gradients": {
    "primary": { "colors": ["#2E7D32", "#60AD5E", "#81C784"] },
    "background": { "colors": ["#1B5E20", "#2E7D32", "#388E3C"] },
    "golden": { "colors": ["#FFD700", "#FFA000", "#FF6F00"] },
    "streak_fire": { "colors": ["#FF6F00", "#FF8F00", "#FFA726"] }
  }
}
```

### 2. Lavender Purple - `lavender`
```json
{
  "colors": {
    "primary": "#7B1FA2",
    "primary_light": "#BA68C8",
    "primary_dark": "#4A0072",
    "secondary": "#FFD700",
    "accent": "#E040FB",
    "background_1": "#4A148C",
    "background_2": "#6A1B9A",
    "background_3": "#7B1FA2",
    "on_primary": "#FFFFFF",
    "on_secondary": "#4A148C",
    "surface": "#4A148C",
    "on_surface": "#FFFFFF",
    "surface_variant": "#6A1B9A",
    "on_surface_variant": "#F3E5F5",
    "glass_background": "#FFFFFF26",
    "glass_border": "#FFFFFF33",
    "glass_highlight": "#FFFFFF4D",
    "text_primary": "#FFFFFF",
    "text_secondary": "#FFFFFFB3",
    "text_hint": "#FFFFFF80",
    "text_on_gradient": "#FFFFFF",
    "shimmer_base": "#7B1FA2",
    "shimmer_highlight": "#BA68C8",
    "card_background": "#FFFFFF26",
    "card_border": "#FFFFFF33",
    "divider": "#FFFFFF33",
    "disabled": "#FFFFFF80"
  },
  "gradients": {
    "primary": { "colors": ["#7B1FA2", "#9C27B0", "#BA68C8"] },
    "background": { "colors": ["#4A148C", "#6A1B9A", "#7B1FA2"] },
    "golden": { "colors": ["#FFD700", "#FFA000", "#FF6F00"] },
    "streak_fire": { "colors": ["#E040FB", "#CE93D8", "#BA68C8"] }
  }
}
```

### 3. Royal Blue - `royal`
```json
{
  "colors": {
    "primary": "#1565C0",
    "primary_light": "#5E92F3",
    "primary_dark": "#003C8F",
    "secondary": "#FFD700",
    "accent": "#00B0FF",
    "background_1": "#0D47A1",
    "background_2": "#1565C0",
    "background_3": "#1976D2",
    "on_primary": "#FFFFFF",
    "on_secondary": "#0D47A1",
    "surface": "#0D47A1",
    "on_surface": "#FFFFFF",
    "surface_variant": "#1565C0",
    "on_surface_variant": "#E3F2FD",
    "glass_background": "#FFFFFF26",
    "glass_border": "#FFFFFF33",
    "glass_highlight": "#FFFFFF4D",
    "text_primary": "#FFFFFF",
    "text_secondary": "#FFFFFFB3",
    "text_hint": "#FFFFFF80",
    "text_on_gradient": "#FFFFFF",
    "shimmer_base": "#1565C0",
    "shimmer_highlight": "#42A5F5",
    "card_background": "#FFFFFF26",
    "card_border": "#FFFFFF33",
    "divider": "#FFFFFF33",
    "disabled": "#FFFFFF80"
  },
  "gradients": {
    "primary": { "colors": ["#1565C0", "#1976D2", "#42A5F5"] },
    "background": { "colors": ["#0D47A1", "#1565C0", "#1976D2"] },
    "golden": { "colors": ["#FFD700", "#FFA000", "#FF6F00"] },
    "streak_fire": { "colors": ["#00B0FF", "#40C4FF", "#80D8FF"] }
  }
}
```

### 4. Sunset Orange - `sunset`
```json
{
  "colors": {
    "primary": "#E65100",
    "primary_light": "#FF8A50",
    "primary_dark": "#AC1900",
    "secondary": "#FFD700",
    "accent": "#FF6F00",
    "background_1": "#BF360C",
    "background_2": "#D84315",
    "background_3": "#E64A19",
    "on_primary": "#FFFFFF",
    "on_secondary": "#BF360C",
    "surface": "#BF360C",
    "on_surface": "#FFFFFF",
    "surface_variant": "#D84315",
    "on_surface_variant": "#FBE9E7",
    "glass_background": "#FFFFFF26",
    "glass_border": "#FFFFFF33",
    "glass_highlight": "#FFFFFF4D",
    "text_primary": "#FFFFFF",
    "text_secondary": "#FFFFFFB3",
    "text_hint": "#FFFFFF80",
    "text_on_gradient": "#FFFFFF",
    "shimmer_base": "#E65100",
    "shimmer_highlight": "#FF9800",
    "card_background": "#FFFFFF26",
    "card_border": "#FFFFFF33",
    "divider": "#FFFFFF33",
    "disabled": "#FFFFFF80"
  },
  "gradients": {
    "primary": { "colors": ["#E65100", "#FF6F00", "#FF9800"] },
    "background": { "colors": ["#BF360C", "#D84315", "#E64A19"] },
    "golden": { "colors": ["#FFD700", "#FFA000", "#FF6F00"] },
    "streak_fire": { "colors": ["#FF6F00", "#FF8F00", "#FFA726"] }
  }
}
```

### 5. Rose Gold - `rose`
```json
{
  "colors": {
    "primary": "#C2185B",
    "primary_light": "#F06292",
    "primary_dark": "#880E4F",
    "secondary": "#FFD700",
    "accent": "#FF4081",
    "background_1": "#880E4F",
    "background_2": "#AD1457",
    "background_3": "#C2185B",
    "on_primary": "#FFFFFF",
    "on_secondary": "#880E4F",
    "surface": "#880E4F",
    "on_surface": "#FFFFFF",
    "surface_variant": "#AD1457",
    "on_surface_variant": "#FCE4EC",
    "glass_background": "#FFFFFF26",
    "glass_border": "#FFFFFF33",
    "glass_highlight": "#FFFFFF4D",
    "text_primary": "#FFFFFF",
    "text_secondary": "#FFFFFFB3",
    "text_hint": "#FFFFFF80",
    "text_on_gradient": "#FFFFFF",
    "shimmer_base": "#C2185B",
    "shimmer_highlight": "#F06292",
    "card_background": "#FFFFFF26",
    "card_border": "#FFFFFF33",
    "divider": "#FFFFFF33",
    "disabled": "#FFFFFF80"
  },
  "gradients": {
    "primary": { "colors": ["#C2185B", "#E91E63", "#F06292"] },
    "background": { "colors": ["#880E4F", "#AD1457", "#C2185B"] },
    "golden": { "colors": ["#FFD700", "#FFA000", "#FF6F00"] },
    "streak_fire": { "colors": ["#FF4081", "#FF80AB", "#F48FB1"] }
  }
}
```

### 6. Midnight Dark - `midnight`
```json
{
  "colors": {
    "primary": "#1A237E",
    "primary_light": "#534BAE",
    "primary_dark": "#000051",
    "secondary": "#FFD700",
    "accent": "#536DFE",
    "background_1": "#0A0E27",
    "background_2": "#1A237E",
    "background_3": "#283593",
    "on_primary": "#FFFFFF",
    "on_secondary": "#0A0E27",
    "surface": "#0A0E27",
    "on_surface": "#FFFFFF",
    "surface_variant": "#1A237E",
    "on_surface_variant": "#E8EAF6",
    "glass_background": "#FFFFFF26",
    "glass_border": "#FFFFFF33",
    "glass_highlight": "#FFFFFF4D",
    "text_primary": "#FFFFFF",
    "text_secondary": "#FFFFFFB3",
    "text_hint": "#FFFFFF80",
    "text_on_gradient": "#FFFFFF",
    "shimmer_base": "#1A237E",
    "shimmer_highlight": "#3949AB",
    "card_background": "#FFFFFF26",
    "card_border": "#FFFFFF33",
    "divider": "#FFFFFF33",
    "disabled": "#FFFFFF80"
  },
  "gradients": {
    "primary": { "colors": ["#1A237E", "#283593", "#3949AB"] },
    "background": { "colors": ["#0A0E27", "#1A237E", "#283593"] },
    "golden": { "colors": ["#FFD700", "#FFA000", "#FF6F00"] },
    "streak_fire": { "colors": ["#536DFE", "#7C4DFF", "#B388FF"] }
  }
}
```

---

## Tips for Creating New Themes

1. **Start with 5 main colors**: `primary`, `primary_light`, `primary_dark`, `secondary`, `accent`
2. **Background progression**: `background_1` (darkest) -> `background_2` -> `background_3` (lightest)
3. **Text colors**: Usually white (`#FFFFFF`) with varying opacity for dark themes
4. **Glass effects**: Use white with low opacity (e.g., `#FFFFFF26` = white at 15% opacity)
5. **Gradients are optional**: If not defined, they're auto-generated from flat colors

## Opacity Reference (for glass effects)
| Opacity | HEX Suffix | Example |
|---------|------------|---------|
| 10% | `1A` | `#FFFFFF1A` |
| 15% | `26` | `#FFFFFF26` |
| 20% | `33` | `#FFFFFF33` |
| 30% | `4D` | `#FFFFFF4D` |
| 50% | `80` | `#FFFFFF80` |
| 70% | `B3` | `#FFFFFFB3` |
| 100% | `FF` | `#FFFFFFFF` |
