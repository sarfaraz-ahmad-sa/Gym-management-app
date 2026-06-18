# 💪 FitGuide — Tumhari 3-Month Fitness App

72 kg → 68 kg + 6-pack abs ka poora safar. Workout plan, diet, progress
tracking aur progress photos — sab ek app mein.

Ye ek **Flutter** mobile app hai (Android + iOS dono pe chalti hai).

---

## ✨ Features

- **Home / Performance Dashboard** — aaj ka workout, goal progress bar, BMI,
  weekly consistency ring (kitne workout/week target ke), habit streak,
  weight trend, aur unlock hone wale **achievements/badges**
- **3-Month Plan** — Month 1 (Foundation), Month 2 (Build & Burn), Month 3 (Cut & Carve)
- **Exercise illustrations + Trainer Guide** — har exercise pe ek figure
  illustration (image), aur tap karke poora "kaise karein" guide:
  step-by-step, common galtiyan, aur saans (breathing) — bilkul gym trainer
  ki tarah
- **Diet plan** — Indian, high-protein, fat-loss meals + rules
- **Progress** — weight log + graph (goal line ke saath), saare records save
- **Progress photos** — camera/gallery se photo, app mein safe save
- **Goals & Habits** — daily habits tracker (paani, neend, protein, steps,
  no-junk) streak ke saath + apne **life goals** target-date ke saath
- **Guide** — beginner rules, 6-pack ka sach, fat loss, recovery, motivation
  (Home ke upar 💡 icon se khulta hai)
- Saara data phone pe locally save hota hai (internet ki zaroorat nahi).

---

## 🚀 Setup (step by step)

### 1. Flutter install karo (ek baar)
- https://docs.flutter.dev/get-started/install se Flutter SDK install karo.
- Check: terminal mein `flutter doctor` chalao. Sab green hona chahiye.
- Android ke liye: Android Studio + ek emulator ya USB se phone (developer mode ON).

### 2. Is project ko ready karo
Is folder (`fitguide/`) ko apne computer pe rakho, phir terminal mein:

```bash
cd fitguide

# Android/iOS platform folders generate karo (zaroori — repo mein included nahi)
flutter create .

# Dependencies download karo
flutter pub get
```

### 3. App chalao
Phone connect karke ya emulator chalu karke:

```bash
flutter run
```

Pehli baar khulne par apna weight/goal/height daalo → "Start my journey".

---

## 🔐 Permissions (photos feature ke liye)

`flutter create .` ke baad ye add karna padega:

### iOS — `ios/Runner/Info.plist` mein `<dict>` ke andar paste karo:
```xml
<key>NSCameraUsageDescription</key>
<string>Progress photos lene ke liye camera chahiye.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Progress photos chunne ke liye gallery chahiye.</string>
```

### Android
Modern Android mein gallery/camera ke liye extra manifest permission ki
zaroorat nahi (image_picker system app use karta hai). Agar koi build error
aaye to `android/app/build.gradle` mein `minSdkVersion` ko `21` ya us se
upar set karo.

---

## 📦 APK banana (phone pe install karne ke liye)

```bash
flutter build apk --release
```
APK yahan milega: `build/app/outputs/flutter-apk/app-release.apk`
Ise phone pe copy karke install kar lo.

---

## 📁 Project structure

```
lib/
  main.dart                 # app entry + onboarding gate
  theme.dart                # colors & dark theme
  models/
    workout.dart            # Exercise / WorkoutDay / MonthPlan
    progress.dart           # WeightEntry / ProgressPhoto
    goal.dart               # Goal + daily Habit definitions
  data/
    plan_data.dart          # 3-month workout plan (content)
    diet_data.dart          # diet plan
    tips_data.dart          # coaching tips
    exercise_guides.dart    # per-exercise illustration + how-to + mistakes
  services/
    storage_service.dart    # local save/load (shared_preferences)
  state/
    app_state.dart          # central state + performance logic (Provider)
  screens/
    root_nav.dart           # bottom navigation
    onboarding_screen.dart
    home_screen.dart        # performance dashboard
    plan_screen.dart
    workout_detail_screen.dart
    diet_screen.dart
    progress_screen.dart
    photos_screen.dart
    goals_screen.dart       # habits + life goals
    tips_screen.dart
assets/
  exercises/                # 15 SVG exercise illustrations
```

---

## ✏️ Plan ko apne hisaab se change karna
- Workouts edit karo: `lib/data/plan_data.dart`
- Diet edit karo: `lib/data/diet_data.dart`
- Tips edit karo: `lib/data/tips_data.dart`

---

## ⚠️ Disclaimer
Ye general fitness/diet guidance hai, medical advice nahi. Koi health
condition (heart, BP, diabetes, injury) ho to start karne se pehle doctor
se baat karo.

Chalo bhai, ab bahane khatam — **Day 1 se shuru!** 🔥
