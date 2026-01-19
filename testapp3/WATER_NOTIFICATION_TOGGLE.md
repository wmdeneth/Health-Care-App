# Water Notification Toggle - User Control

## ✅ What's Been Added

### Profile Screen Enhancement
In the **Account** screen (`lib/screens/profile_screen.dart`), users can now see and control their water notification settings with a toggle switch.

#### New Features:
1. **Water Reminders Toggle Switch** - Users can enable/disable water notifications directly in the app
2. **Real-time Status** - Toggle shows current state and description:
   - **Enabled**: "You will receive water reminders daily"
   - **Disabled**: "Reminders are disabled"
3. **Automatic Scheduling** - When toggled:
   - **ON**: Automatically schedules daily water reminders (8 AM - 10 PM, personalized based on weight)
   - **OFF**: Cancels all scheduled water notifications
4. **Firestore Sync** - The `waterEnabled` field is updated in Firestore immediately
5. **User Feedback** - Shows success/error messages using snackbars

## 📱 How It Works

### User Flow:
1. User opens **Account** tab in the app
2. User sees their profile with the new **Water Reminders** card
3. User toggles the switch to enable/disable
4. App updates Firestore and schedules/cancels notifications
5. Success message confirms the change

### Behind the Scenes:
```
User Toggles Switch
        ↓
_toggleWaterNotifications() called
        ↓
Firestore waterEnabled field updated
        ↓
scheduleDailyHydrationReminders() OR cancelHydrationReminders()
        ↓
Notifications scheduled/cancelled on device
        ↓
Success/Error snackbar shown to user
```

## 🔧 Technical Implementation

### State Variables Added:
```dart
bool _waterNotificationsEnabled = false;  // Tracks toggle state
```

### Methods Added:

#### `_loadWaterNotificationStatus()`
- Runs on app startup
- Loads the current `waterEnabled` value from Firestore
- Sets the initial toggle state

#### `_toggleWaterNotifications(bool newValue)`
- Called when user flips the switch
- Updates Firestore with new value
- Calls `scheduleDailyHydrationReminders()` if enabled
- Calls `cancelHydrationReminders()` if disabled
- Shows success/error messages
- Reverts toggle on error for UX consistency

### Imports Added:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';
```

## 📊 Firestore Integration

### Field Being Updated:
```json
users/{uid}:
{
  "waterEnabled": true/false
}
```

### Behavior:
- When `waterEnabled = true`: 
  - App schedules 8 personalized notifications between 8 AM - 10 PM
  - Each notification reminds user to drink 250ml
  - Total notifications = dailyWaterGoal ÷ 250ml

- When `waterEnabled = false`:
  - All scheduled notifications are cancelled
  - User won't receive any water reminders

## ✨ UI Details

### Water Reminders Card:
Located in the **Account** tab's profile view section:

```
┌─────────────────────────────────────────┐
│ Water Reminders              [Toggle] ◯→ │
│ You will receive water reminders daily   │
└─────────────────────────────────────────┘
```

**Visual States:**
- **Enabled**: Toggle is ON (blue/enabled color), text says "You will receive water reminders daily"
- **Disabled**: Toggle is OFF (gray/disabled color), text says "Reminders are disabled"

**Feedback:**
- Enabling shows: "Water reminders enabled" snackbar
- Disabling shows: "Water reminders disabled" snackbar
- Errors show error message snackbar

## 🧪 Testing the Feature

### Manual Test Steps:
1. Open the app and go to **Account** tab
2. Look for the **Water Reminders** card (with switch)
3. Toggle the switch ON
   - ✓ Should show "Water reminders enabled" message
   - ✓ Should schedule notifications
   - ✓ Firestore should update `waterEnabled: true`
4. Toggle the switch OFF
   - ✓ Should show "Water reminders disabled" message
   - ✓ Should cancel notifications
   - ✓ Firestore should update `waterEnabled: false`
5. Kill and restart the app
   - ✓ Toggle should remember the last state (from Firestore)
6. Verify notifications appear at scheduled times (when enabled)

## 📁 Files Modified

### `lib/screens/profile_screen.dart`
- Added imports for Firestore and notification service
- Added `_waterNotificationsEnabled` state variable
- Added `_loadWaterNotificationStatus()` method
- Added `_toggleWaterNotifications()` method
- Added Water Reminders Card UI in the profile view section
- Updated `initState()` to load water notification status on startup

## 💡 Architecture

The feature integrates seamlessly with existing systems:

```
Profile Screen (UI)
        ↓
_toggleWaterNotifications() (Logic)
        ↓
Firestore (Data) ← waterEnabled field
        ↓
Notification Service (Scheduling)
        ↓
Device Notifications (User feedback)
```

## 🚀 Future Enhancements

Possible improvements:
- Customize notification times (currently 8 AM - 10 PM)
- Set custom notification intervals (currently 250ml)
- Notification sound/vibration preferences
- View upcoming scheduled notifications
- Manual trigger for water reminder (test/now button)

---

**Status**: ✅ Ready for testing on emulator/device
