# DexCom App Theme Update

## Overview

The entire DexCom application has been updated with a comprehensive, professional theme using blue, white, and green colors with glucose-specific status indicators.

## New Theme System

### Created Files

- **`lib/theme/app_theme.dart`** - Centralized theme configuration file containing:
  - Comprehensive color palette
  - Light and dark theme definitions
  - Glucose status color mapping functions
  - Theme data for all Material Design components

## Color Palette

### Primary Colors

- **Primary Blue** (`#2563EB`) - Main action color
- **Light Blue** (`#3B82F6`) - Secondary actions
- **Dark Blue** (`#1E40AF`) - Dark mode primary

### Status Colors (Glucose-Related)

- **Success Green** (`#10B981`) - Normal glucose range (70-140 mg/dL)
- **Light Green** (`#6EE7B7`) - Good glucose level (100-140 mg/dL)
- **Dark Green** (`#059669`) - Dark mode success

- **Warning Orange** (`#F59E0B`) - Slightly elevated (140-180 mg/dL)
- **Danger Red** (`#FEF5454B`) - High/Critical (>180 mg/dL)
- **Low Red** (`#EF4444`) - Hypoglycemia (<70 mg/dL)
- **Caution Yellow** (`#FCD34D`) - Warning state

### Neutral Colors

- **White** (`#FFFFFF`)
- **Light Gray** (`#F3F4F6`)
- **Medium Gray** (`#D1D5DB`)
- **Dark Gray** (`#4B5563`)

### Dark Mode Colors

- **Dark Background** (`#111827`)
- **Dark Surface** (`#1F2937`)
- **Dark Card** (`#2D3748`)

## Updated Files

### Core Files

1. **`lib/main.dart`**

   - Updated to use `AppTheme.lightTheme` and `AppTheme.darkTheme`
   - Login page redesigned with new color scheme
   - System theme mode detection

2. **`lib/providers/theme_provider.dart`**
   - Updated to use the new `AppTheme` system

### Screen Files

3. **`lib/screens/home_screen.dart`**

   - Updated navigation colors
   - FAB (Floating Action Button) now uses `successGreen`
   - AppBar and navigation colors aligned with theme

4. **`lib/screens/dashboard_screen.dart`**

   - **Glucose status display** - Now uses dynamic colors based on glucose values
   - Current glucose level shows status-specific color
   - Chart line color changed to `successGreen`
   - Meal markers use `warningOrange`
   - Status indicators updated with proper glucose status functions:
     - `getGlucoseStatusColor()` - Returns appropriate color for glucose value
     - `getGlucoseStatusIcon()` - Returns appropriate icon
     - `getGlucoseStatusText()` - Returns status text

5. **`lib/screens/add_meal_screen.dart`**

   - Meal type icons redesigned:
     - Breakfast: `warningOrange`
     - Lunch: `primaryBlue`
     - Dinner: `dangerRed`
     - Snack: `successGreen`
   - Success confirmation uses `successGreen`
   - Form fields updated with new styling

6. **`lib/screens/statistics_screen.dart`**

   - Weekly statistics cards with theme-aligned colors
   - TIR (Time In Range) indicator uses `successGreen`
   - Bar chart uses `successGreen` for glucose visualization
   - Status icons updated with theme colors

7. **`lib/screens/history_screen.dart`**

   - Glucose status colors now use theme color system:
     - Low: `lowRed`
     - High: `dangerRed`
     - Normal: `successGreen`

8. **`lib/screens/settings_screen.dart`**

   - Target range sliders color-coded:
     - Lower limit slider: `successGreen`
     - Upper limit slider: `warningOrange`
   - Unit selection buttons use `primaryBlue`
   - Notifications section with `warningOrange` icon
   - All cards and controls updated

9. **`lib/screens/signup_screen.dart`**
   - Updated with new theme colors
   - Form fields with proper styling
   - Account creation button uses `successGreen`
   - Icons and text colors aligned with theme

## Theme Features

### Automatic Light/Dark Mode Support

- Both light and dark themes are fully configured
- System preference detection
- Manual theme toggle in AppBar

### Consistent Component Styling

- Cards with 0 elevation and subtle borders
- Rounded corners (12-16px) throughout
- Unified input field styling
- Consistent button styles

### Glucose-Aware Design

- Dynamic color assignment based on glucose levels
- Status indicators that change color contextually
- Easy-to-read status text and icons
- Visual feedback for glucose trends

### Material Design 3

- Uses Material Design 3 components
- Proper color scheme implementation
- Theme data for all standard widgets

## Usage

To use the theme throughout the app, simply import:

```dart
import '../theme/app_theme.dart';

// Use in theme definition:
theme: AppTheme.lightTheme,
darkTheme: AppTheme.darkTheme,

// Use specific colors:
color: AppTheme.successGreen,
color: AppTheme.getGlucoseStatusColor(112), // Dynamic glucose color
```

## Testing

All files have been compiled and verified for errors. The theme system is ready for production use.

---

**Last Updated:** December 11, 2025
