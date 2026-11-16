# Auto-Delete Expired Products Feature

## Overview

This feature allows users to automatically delete expired products from their pantry once per day. This setting is **Android only** and is disabled by default.

## Components

### 1. Settings UI (`lib/settings_screen.dart`)
- New toggle switch in the Settings screen (visible only on Android)
- Title: "Auto-delete expired products"
- Description: "Automatically remove expired products once a day (Android only)"
- The toggle is conditionally rendered using `if (!kIsWeb)`

### 2. Settings Storage (`lib/service/app_settings.dart`)
- Added `_autoDeleteExpiredProducts` boolean flag
- New getter: `autoDeleteExpiredProducts`
- New method: `setAutoDeleteExpiredProducts(bool enabled)` - handles scheduling/cancelling tasks
- Settings are persisted in the database with key `auto_delete_expired`

### 3. Expired Products Service (`lib/service/expired_products_service.dart`)
- `deleteExpiredProducts()` - Main method that deletes all expired products
  - Fetches all products
  - Compares expiration dates with current date
  - Deletes products that are past their expiration date
  - Returns count of deleted products
- `getExpiredProducts()` - Helper method to retrieve expired products without deleting

### 4. WorkManager Service (`lib/service/work_manager_service.dart`)
- Manages Android background job scheduling using `workmanager` package
- `scheduleDeleteExpiredProductsTask()` - Schedules daily task
  - Runs once per day
  - Initial delay of 1 hour to avoid startup overhead
  - No battery constraint required
- `cancelDeleteExpiredProductsTask()` - Cancels scheduled task
- Callback dispatcher handles task execution safely

### 5. Main Initialization (`lib/main.dart`)
- Initializes WorkManager on app startup
- Schedules task if setting is enabled

## How It Works

1. **User enables the toggle** in Settings → Auto-delete expired products
2. **AppSettings.setAutoDeleteExpiredProducts(true)** is called
3. **WorkManagerService.scheduleDeleteExpiredProductsTask()** schedules the daily task
4. **Every 24 hours**, the background task runs
5. **ExpiredProductsService.deleteExpiredProducts()** is executed
6. All products with expiration dates before today are removed from the database

## Database Changes

The `settings` table now stores:
- Key: `auto_delete_expired`
- Value: `'true'` or `'false'`

## String Localization

Added Italian and English strings:
- `autoDeleteExpiredProducts` - "Auto-delete expired products" / "Cancella automaticamente prodotti scaduti"
- `autoDeleteExpiredProductsDescription` - Feature description with Android-only note

## Dependencies Added

- `workmanager: ^0.5.2` - For Android background job scheduling

## AndroidManifest.xml Changes

Added permissions:
- `android.permission.SCHEDULE_EXACT_ALARM` - Allows precise scheduling of tasks

Existing permissions utilized:
- `android.permission.RECEIVE_BOOT_COMPLETED` - Already present

## Testing

To test this feature:

1. **Enable the toggle** in Settings on an Android device
2. **Add products** with past expiration dates
3. **Wait for the next scheduled task** or debug with WorkManager tools
4. **Verify products** are removed from the pantry

### Debug Notes
- WorkManager initializes with `isInDebugMode: kDebugMode` for easy debugging
- Log messages are printed when tasks are scheduled, cancelled, or executed
- The callback dispatcher has error handling with debug logging

## Limitations

- **Android only**: Uses WorkManager which is Android-specific
- **Once per day**: Configured to run daily (can be modified in `scheduleDeleteExpiredProductsTask`)
- **No user notification**: Deleted products are silently removed (can be enhanced with notifications)
- **Requires WorkManager**: Depends on Android WorkManager library

## Future Enhancements

1. Add notification when products are auto-deleted
2. Add log of deleted products
3. Make deletion frequency configurable (daily, weekly, etc.)
4. Add dry-run mode to preview what would be deleted
5. Add exempt categories (e.g., don't delete certain items)
