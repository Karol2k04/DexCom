# DexCom Theme Color Reference

## Color Swatches

### Main Brand Colors

```
Primary Blue:        #2563EB
Light Blue:          #3B82F6
Dark Blue:           #1E40AF
```

### Glucose Status Colors

```
Success Green:       #10B981  (Normal range: 70-140 mg/dL)
Light Green:         #6EE7B7  (Good: 100-140 mg/dL)
Dark Green:          #059669  (Dark mode success)

Warning Orange:      #F59E0B  (Elevated: 140-180 mg/dL)
Danger Red:          #EF4444  (High: >180 mg/dL)
Low Red:             #EF4444  (Low/Hypo: <70 mg/dL)
Caution Yellow:      #FCD34D  (Caution state)
```

### Neutral Colors

```
White:               #FFFFFF
Light Gray:          #F3F4F6
Medium Gray:         #D1D5DB
Dark Gray:           #4B5563
```

### Dark Mode

```
Dark Background:     #111827
Dark Surface:        #1F2937
Dark Card:           #2D3748
```

## Glucose Status Mapping

| Glucose Level | Status   | Color          | Icon                   |
| ------------- | -------- | -------------- | ---------------------- |
| < 70 mg/dL    | Low      | Low Red        | ⚠️ warning_rounded     |
| 70-100 mg/dL  | Normal   | Success Green  | ✓ check_circle_rounded |
| 100-140 mg/dL | Good     | Light Green    | ✓ check_circle_rounded |
| 140-180 mg/dL | Elevated | Warning Orange | ℹ️ info_rounded        |
| 180-250 mg/dL | High     | Danger Red     | ✗ error_rounded        |
| > 250 mg/dL   | Critical | Danger Red     | ✗ error_rounded        |

## Component Colors

### AppBar

- Light Mode: White background with Primary Blue text
- Dark Mode: Dark Surface background with Light Blue text

### Cards

- Light Mode: White with subtle gray border
- Dark Mode: Dark Card with darker border

### Buttons

- Primary Action: Primary Blue background
- Secondary Action: Light Gray border (light mode) / Dark Surface border (dark mode)
- Success Action: Success Green background
- Disabled: Light Gray

### Text

- Primary: Dark Blue (light) / White (dark)
- Secondary: Dark Gray (light) / Gray 400 (dark)
- Tertiary: Medium Gray

### Input Fields

- Background: Light Gray (light) / Dark Surface (dark)
- Border (Active): Primary Blue
- Border (Inactive): None (filled style)

## Implementation Highlights

### Dynamic Glucose Colors

The app implements dynamic color assignment based on glucose readings using:

- `AppTheme.getGlucoseStatusColor(double value)` - Returns appropriate color
- `AppTheme.getGlucoseStatusText(double value)` - Returns status text
- `AppTheme.getGlucoseStatusIcon(double value)` - Returns status icon

### Consistency Across Screens

- All 7 main screens use the theme system
- Login/SignUp screen themed
- Bottom navigation bar matches theme
- All interactive elements use theme colors

### Accessibility Features

- High contrast ratios maintained
- Color-blind friendly status indicators (uses icons + color)
- Clear visual hierarchy
- Readable in both light and dark modes

## Quick Reference for Development

```dart
// Import the theme
import 'theme/app_theme.dart';

// Apply theme to MaterialApp
MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
)

// Use specific colors
Container(
  color: AppTheme.successGreen,
  child: Text('Success!'),
)

// Dynamic glucose coloring
Container(
  color: AppTheme.getGlucoseStatusColor(glucose),
  child: Text(AppTheme.getGlucoseStatusText(glucose)),
)
```

---

**Design System Version:** 1.0
**Created:** December 11, 2025
