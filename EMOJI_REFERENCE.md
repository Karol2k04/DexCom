# 🎨 DexCom Visual Enhancement - Quick Reference

## Emoji Usage Guide

### Glucose Status Emojis 📊

| Value   | Range    | Emoji | Meaning                |
| ------- | -------- | ----- | ---------------------- |
| < 70    | Low      | ⚠️    | Warning - Critical Low |
| 70-100  | Normal   | ✅    | Good - Normal Range    |
| 100-140 | Good     | 🎯    | Target - Optimal       |
| 140-180 | Elevated | ⚡    | Warning - High         |
| 180-250 | High     | 🔴    | Danger - Very High     |
| > 250   | Critical | 🆘    | Emergency - Critical   |

### Navigation Emojis 🏠

| Screen     | Emoji | Meaning          |
| ---------- | ----- | ---------------- |
| Dashboard  | 📊    | Data/Chart       |
| History    | 📋    | Records/List     |
| Statistics | 📈    | Growth/Analytics |
| Settings   | ⚙️    | Configuration    |
| Add Meal   | 🍴    | Food/Dining      |

### Meal Type Emojis 🍽️

| Meal      | Emoji | Time    |
| --------- | ----- | ------- |
| Breakfast | 🍳    | Morning |
| Lunch     | 🍽️    | Midday  |
| Dinner    | 🍖    | Evening |
| Snack     | 🍎    | Anytime |

### Status & Action Emojis ✨

| Purpose    | Emoji | Usage        |
| ---------- | ----- | ------------ |
| Time       | 🕐    | Timestamps   |
| Trend Up   | 📈    | Increasing   |
| Trend Down | 📉    | Decreasing   |
| Stable     | ➡️    | No change    |
| Insulin    | 💉    | Injection    |
| Check      | ✅    | Success      |
| Alert      | ⚠️    | Warning      |
| Success    | ✅    | Confirmation |

### Section Headers 🎯

| Section       | Emoji |
| ------------- | ----- |
| Settings      | ⚙️    |
| Target Range  | 🎯    |
| Units         | 📏    |
| Notifications | 🔔    |
| History       | 📋    |
| Statistics    | 📊    |
| Dashboard     | 📊    |
| Add Meal      | 🍴    |
| App Title     | 🩺    |

---

## Color Coding Guide 🎨

### By Status

| Status  | Color    | Hex     | Usage                       |
| ------- | -------- | ------- | --------------------------- |
| Success | Green    | #10B981 | Normal glucose, good range  |
| Warning | Orange   | #F59E0B | Elevated glucose            |
| Danger  | Red      | #EF4444 | High glucose                |
| Low     | Dark Red | #DC2626 | Critical low glucose        |
| Primary | Blue     | #2563EB | Navigation, primary actions |
| Neutral | Gray     | #6B7280 | Text, secondary info        |

### By Meal Type

| Meal      | Color  | Emoji |
| --------- | ------ | ----- |
| Breakfast | Orange | 🍳    |
| Lunch     | Blue   | 🍽️    |
| Dinner    | Red    | 🍖    |
| Snack     | Green  | 🍎    |

---

## Design Elements 🖼️

### Spacing

- **Card Padding**: 16px
- **Inner Spacing**: 12px
- **Large Gap**: 16px
- **Small Gap**: 4-8px

### Typography

| Purpose       | Size    | Weight      |
| ------------- | ------- | ----------- |
| Screen Title  | 24px    | Bold (W700) |
| Section Title | 16px    | W600        |
| Main Value    | 28-64px | Bold        |
| Label         | 10-14px | Normal      |
| Emoji         | 16-28px | N/A         |

### Border Radius

- **Cards**: 16px
- **Buttons**: 12-16px
- **Badges**: 8-12px
- **Input Fields**: 12px

### Shadows

- **On Selection**: Small shadow (#color × 0.2 opacity)
- **Elevation**: 0 (flat design)
- **Hover**: Subtle shadow

---

## Screen-Specific Enhancements

### 📊 Dashboard

```
Header: 📊 Current Level [Status Badge with emoji]
Glucose: [Large 64px number] [Emoji] | 📈 Stable | 🕐 2 min ago
Cards: [📊 24h Avg] [🎯 TIR] [⚠️ Episodes]
```

### 📋 History

```
Header: 📋 Measurement History
Items:
  🕐 [Time] [Status emoji] [Glucose] | [Trend emoji]
  Badges: 🍽️ [Meal] | 💉 [Insulin]
```

### 📈 Statistics

```
Cards: 🎯 [Value] | 📈 [Value] | 📊 [Value]
Format: Large emoji (24px) + bold number (24px) + label
```

### ⚙️ Settings

```
Sections:
  🎯 Target Range [Sliders]
  📏 Units [Buttons]
  🔔 Notifications [Toggles with 🔴 ⚡ emojis]
```

### 🍴 Add Meal

```
Header: 🍴 Add Meal
Selection: [🍳] [🍽️] [🍖] [🍎]
Success: ✅ Meal saved! | Your meal has been recorded
```

### 🏠 Home

```
AppBar: 🩺 DexCom
Navigation: 📊 Dashboard | 📋 History | 📈 Stats | ⚙️ Settings
```

---

## Implementation Checklist ✅

### Dashboard Screen ✅

- [x] Emoji in header (📊)
- [x] Status badge with emoji
- [x] 64px glucose number
- [x] Trend indicator (📈)
- [x] Timestamp with emoji (🕐)
- [x] 3 stat cards with emojis
- [x] Episodes with 🔴 ⚡

### History Screen ✅

- [x] Header emoji (📋)
- [x] Time emoji (🕐)
- [x] Glucose status emoji
- [x] Trend emojis (📈 📉 ➡️)
- [x] Meal badge (🍽️)
- [x] Insulin badge (💉)
- [x] Color-coded containers

### Statistics Screen ✅

- [x] Emoji headers (🎯 📈 📊)
- [x] Large emoji display
- [x] Colored stat cards
- [x] 16px border radius

### Settings Screen ✅

- [x] Header emoji (⚙️)
- [x] Section emojis (🎯 📏 🔔)
- [x] Alert emojis (🔴 ⚡)
- [x] Toggle styling

### Add Meal Screen ✅

- [x] Header emoji (🍴)
- [x] Meal emojis (🍳 🍽️ 🍖 🍎)
- [x] Large emoji display (28px)
- [x] Selection feedback
- [x] Success emoji (✅)

### Home Screen ✅

- [x] Title emoji (🩺)
- [x] Navigation emojis (📊 📋 📈 ⚙️)
- [x] Emoji size (20px)
- [x] Color coding

---

## Testing Checklist 🧪

### Visual

- [ ] Emojis display correctly
- [ ] Colors match specifications
- [ ] Spacing is consistent
- [ ] Rounded corners are 16px
- [ ] Text is readable

### Functional

- [ ] Tap/click on emoji buttons works
- [ ] Selection states show correctly
- [ ] Color changes reflect status
- [ ] Dark mode looks good
- [ ] Responsive on different sizes

### Accessibility

- [ ] Text contrast is good
- [ ] Emoji don't replace required text
- [ ] Labels are present for all inputs
- [ ] Touch targets are large enough

---

## Files Modified 📝

| File                     | Changes                                   |
| ------------------------ | ----------------------------------------- |
| `dashboard_screen.dart`  | 4 emoji additions, stat card enhancements |
| `history_screen.dart`    | 5 emoji additions, badge styling          |
| `statistics_screen.dart` | 3 emoji stat cards                        |
| `settings_screen.dart`   | 3 emoji headers, notification emojis      |
| `add_meal_screen.dart`   | 5 meal emojis, success enhancement        |
| `home_screen.dart`       | 5 navigation emojis, title emoji          |
| `app_theme.dart`         | New getGlucoseStatusEmoji() function      |

---

## Quick Copy-Paste Guide 📋

### Glucose Status Emoji Function

```dart
String statusEmoji = AppTheme.getGlucoseStatusEmoji(glucoseValue);
```

### Meal Type Emoji

```dart
// Breakfast: 🍳
// Lunch: 🍽️
// Dinner: 🍖
// Snack: 🍎
```

### Status Colors

```dart
AppTheme.primaryBlue      // #2563EB
AppTheme.successGreen     // #10B981
AppTheme.warningOrange    // #F59E0B
AppTheme.dangerRed        // #EF4444
AppTheme.lowRed           // #DC2626
```

### Card Styling

```dart
shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(16),
)
```

---

**Note**: All emojis render natively on iOS and Android. No additional libraries needed!

Last Updated: 2024
Status: Complete ✅
