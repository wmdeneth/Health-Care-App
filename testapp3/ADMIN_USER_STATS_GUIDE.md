# Admin Panel User Stats & Water Notifications - Implementation Guide

## ✅ What's Been Done

### Admin Panel Updates:
1. **Enhanced Users Table** in admin panel now shows:
   - Username
   - Total Steps count
   - Water Intake (ml)
   - Daily Water Goal (ml)
   - Water Progress Bar (visual %)
   - Enable/Disable Water Notification buttons

2. **New Functions Added:**
   - `enableWaterNotification(userId)` - Enables water reminders for a user
   - `disableWaterNotification(userId)` - Disables water reminders for a user

### Firebase Fields:
Users collection now tracks:
```json
{
  "nickname": "User Name",
  "totalSteps": 5234,
  "currentIntake": 750,
  "dailyWaterGoal": 2450,
  "waterEnabled": true
}
```

## 🔧 What Needs to Be Done in Flutter App

### 1. Track Step Count
In the Flutter app, save total steps to Firestore:

```dart
// In home_screen.dart or step_counter_service.dart
await FirebaseFirestore.instance
    .collection('users')
    .doc(FirebaseAuth.instance.currentUser!.uid)
    .set({
      'totalSteps': _todaySteps,
    }, SetOptions(merge: true));
```

### 2. Track Water Intake
Water intake is already tracked via `currentIntake` field when user taps "I Drank 250ml":

```dart
// In notification_service.dart (already implemented)
'currentIntake': FieldValue.increment(250)
```

### 3. Calculate & Save Daily Water Goal
When user updates weight, calculate goal:

```dart
// In profile_screen.dart
double dailyGoal = weightKg * 35;
dailyGoal = dailyGoal.clamp(1000.0, 5000.0);

await FirebaseFirestore.instance
    .collection('users')
    .doc(uid)
    .set({
      'dailyWaterGoal': dailyGoal.round(),
    }, SetOptions(merge: true));
```

### 4. React to waterEnabled Flag
Listen to waterEnabled changes in the app:

```dart
// In home_screen.dart or main notification setup
StreamBuilder(
  stream: FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final waterEnabled = snapshot.data!['waterEnabled'] ?? false;
      
      if (waterEnabled && !_remindersScheduled) {
        // Schedule water notifications
        await scheduleDailyHydrationReminders();
      } else if (!waterEnabled && _remindersScheduled) {
        // Cancel water notifications
        await cancelHydrationReminders();
      }
    }
    return...
  }
)
```

## 📊 Admin Panel Workflow

1. **Admin opens Users tab** → Sees all users with their stats
2. **Admin clicks "Enable" button** → Sets `waterEnabled: true` in Firestore
3. **Flutter app detects change** → Starts scheduling water notifications
4. **User sees notifications** → Taps "I Drank 250ml"
5. **App updates currentIntake** → Admin sees water progress update in real-time

## 🧪 Testing Checklist

- [ ] Step count appears in admin panel
- [ ] Water intake updates when user drinks
- [ ] Water progress bar shows correct percentage
- [ ] "Enable" button turns to "Disable" after clicking
- [ ] App receives waterEnabled change and starts notifications
- [ ] "Disable" button stops notifications on app

## 📁 Files to Update in Flutter App

1. **lib/screens/home_screen.dart**
   - Add step count saving
   - Add waterEnabled listener

2. **lib/screens/profile_screen.dart**
   - Calculate & save dailyWaterGoal on weight update

3. **lib/services/notification_service.dart**
   - Already tracks currentIntake ✓

4. **lib/services/step_counter_service.dart**
   - Save totalSteps to Firestore

## 💡 How It Works

```
Admin Panel                  Firebase              Flutter App
    ↓                            ↓                      ↓
Shows user stats ←→ totalSteps ←→ Tracks steps
                  ←→ currentIntake ←→ Tracks water
                  ←→ dailyWaterGoal ← Calculates goal
                  ←→ waterEnabled ← Admin clicks Enable/Disable
                                    ↓
                            Starts/Stops notifications
```

## ✨ Features Created

| Feature | Admin | App |
|---------|-------|-----|
| View user steps | ✓ | Updates to Firestore |
| View water intake | ✓ | Updates via notifications |
| View daily goal | ✓ | Calculates on profile update |
| View water progress | ✓ | Real-time graph |
| Enable notifications | ✓ | Listens to change |
| Disable notifications | ✓ | Cancels reminders |

---

**Next Step:** Update the Flutter app to save these fields to Firestore!
