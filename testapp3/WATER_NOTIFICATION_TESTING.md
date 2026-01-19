# Water Notification Testing Guide

## Overview
This guide explains how to test the water notification functionality in your Flutter app.

## Features Being Tested

The water notification system includes:
1. **Personalized Water Goals** - Calculated based on user's weight (weightKg × 35ml)
2. **Smart Scheduling** - Notifications spread evenly between 8:00 AM - 10:00 PM
3. **Interactive Actions** - "I Drank 250ml" button on notifications
4. **History Tracking** - All notifications logged to Firestore
5. **Auto-increment** - Tapping notification action automatically updates water intake

## How to Run Tests

### Method 1: Using the Test Screen (Recommended)
1. Launch the app
2. Tap the **science flask icon** (🧪) in the top-right corner of the home screen
3. Tap **"Run All Tests"** to execute the complete test suite
4. View results in the on-screen log

### Method 2: Using the Home Screen Button
1. Scroll down on the home screen
2. Find the **"Testing Tools"** card (purple)
3. Tap **"Run All Tests"**
4. Check the debug console for detailed output

### Method 3: Using Quick Tests
From the test screen, you can run individual tests:
- **Enable** - Enables water reminders for your account
- **Schedule** - Schedules daily water notifications
- **Test Now** - Sends an immediate test notification
- **Profile** - Checks your profile data for goal calculation

## Test Suite Details

### Test 1: Enable Water Reminders
- Sets `waterEnabled = true` in Firestore
- Verifies the setting was saved correctly
- **Expected**: ✅ Pass

### Test 2: Schedule Notifications
- Calls `scheduleDailyHydrationReminders()`
- Calculates daily water goal from user profile
- Schedules notifications between 8 AM - 10 PM
- Saves scheduled notifications to Firestore
- **Expected**: ✅ Pass with multiple notifications scheduled

### Test 3: Immediate Test Notification
- Sends a notification immediately (ID: 7777)
- Includes "I Drank 250ml" action button
- **Expected**: ✅ Pass + notification appears on device

### Test 4: User Profile Data
- Checks if user has weight/height data
- Calculates expected water goal
- Shows current `dailyWaterGoal` value
- **Expected**: ✅ Pass (⚠️ Warning if no weight data)

### Test 5: Notification History
- Retrieves past 7 days of notifications
- Shows recent notification details
- **Expected**: ✅ Pass (may be empty if no history)

### Test 6: Drink Water Action
- Increments `currentIntake` by 250ml
- Verifies the increment worked correctly
- **Expected**: ✅ Pass with intake increased by 250ml

### Test 7: Notification Permissions
- Verifies notification plugin is available
- **Expected**: ✅ Pass (manual check in settings required)

## Prerequisites

### User Must Be Logged In
All tests require an authenticated Firebase user. Guest mode will not work.

### Profile Data (Optional but Recommended)
For accurate water goal calculation:
1. Go to **Account** screen
2. Add your **Weight** (in kg)
3. Optionally add **Height** (in cm) for BMI-based adjustment
4. Save profile

**Goal Calculation:**
- Base: `weightKg × 35ml`
- Adjusted by BMI if height is provided
- Range: 1000ml - 5000ml
- Default: 2000ml (if no weight data)

### Notification Permissions
Make sure notifications are enabled:
1. Go to **Settings** > **Apps** > **Your App**
2. Enable **Notifications**
3. Allow **Alarms & Reminders** (Android 12+)

## Expected Output

### Console Output Example:
```
════════════════════════════════════════
🚀 WATER NOTIFICATION TEST SUITE
════════════════════════════════════════

🧪 Test 1: Enabling water reminders...
✅ Test passed: Water reminders enabled

🧪 Test 2: Scheduling water notifications...
✅ Test passed: 8 notifications scheduled
   - Notification 1: Time to Hydrate! 💧 at 2026-01-18T08:00:00.000
   - Notification 2: Time to Hydrate! 💧 at 2026-01-18T09:45:00.000
   - Notification 3: Time to Hydrate! 💧 at 2026-01-18T11:30:00.000

🧪 Test 3: Sending immediate test notification...
✅ Test passed: Immediate notification sent
   Check your device for the notification!

🧪 Test 4: Checking user profile data...
   User profile:
   - Weight: 70.0 kg
   - Height: 175.0 cm
   - Daily water goal: 2450 ml
   - Expected goal (weight × 35): 2450 ml
✅ Test passed: User has profile data for goal calculation

🧪 Test 5: Checking notification history...
   Found 3 notifications in the last 7 days
   - Time to Hydrate! 💧 at 2026-01-18 14:30:00.000
     Drank: Yes ✓
   - Time to Hydrate! 💧 at 2026-01-18 12:15:00.000
     Drank: No ✗

🧪 Test 6: Testing drink water action...
   Current water intake: 500 ml
   New water intake: 750 ml
✅ Test passed: Water intake incremented correctly

🧪 Test 7: Checking notification permissions...
✅ Test passed: Notification plugin is available
   Make sure notifications are enabled in app settings

════════════════════════════════════════
📊 TEST SUMMARY
════════════════════════════════════════
✅ PASS - Enable Water Reminders
✅ PASS - User Profile Data
✅ PASS - Notification Permissions
✅ PASS - Schedule Notifications
✅ PASS - Immediate Test Notification
✅ PASS - Notification History
✅ PASS - Drink Water Action

Total: 7 tests
Passed: 7
Failed: 0
Success Rate: 100.0%
════════════════════════════════════════
```

## Troubleshooting

### Issue: Tests fail with "No user logged in"
**Solution**: Log in to the app first using a Firebase account

### Issue: No notifications appear
**Solution**: 
- Check notification permissions in system settings
- Verify "Alarms & Reminders" permission is granted
- Try the "Test Now" button to send an immediate notification

### Issue: Daily goal is 2000ml (default)
**Solution**: Add your weight to your profile in the Account screen

### Issue: Notifications not scheduling
**Solution**:
- Run Test 1 (Enable) first
- Check console for any error messages
- Verify Firebase connection is working

### Issue: "I Drank 250ml" button doesn't work
**Solution**:
- This updates Firestore in the background
- Check notification history screen to verify
- Run Test 6 to verify the increment works

## Verifying Notifications Work

1. **Run all tests** - Should show 100% pass rate
2. **Wait for scheduled time** - Check if notification appears
3. **Tap notification action** - "I Drank 250ml" button
4. **Check history** - Go to Notifications screen > History tab
5. **Check intake** - Water card on home screen should update

## Admin Dashboard

The Admin panel (Admin/src/App.jsx) shows:
- Users with water notifications enabled
- Current water goals
- Can be accessed at `http://localhost:5173` (if running)

## Next Steps

After successful testing:
1. Monitor notifications throughout the day
2. Check notification history regularly
3. Verify water intake updates correctly
4. Test on different devices/Android versions

## Files Involved

- `lib/services/notification_service.dart` - Core notification logic
- `lib/services/water_notification_test.dart` - Test suite
- `lib/screens/water_notification_test_screen.dart` - Test UI
- `lib/screens/home_screen.dart` - Home screen integration
- `lib/screens/notifications_screen.dart` - History display
- `lib/services/notification_history_service.dart` - History tracking

---

**Note**: Always check the debug console for detailed output when running tests.
