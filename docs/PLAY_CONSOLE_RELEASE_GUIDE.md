# Banana Escape Play Console Release Guide

This guide is the shortest safe path from local build to Google Play internal testing and then production.

## 1. Final decisions before creating the Play app

- Choose your final package name once. Do not create the Play app until this is locked.
- Recommended pattern: `com.yourstudio.bananaescape`
- Set the final `applicationId` and `namespace` in `android/app/build.gradle`
- Move `MainActivity.kt` into the matching package folder
- Replace launcher icon, feature graphic, screenshots, and privacy policy URL

## 2. Create your upload keystore

Create a keystore and keep it backed up outside the repo.

Example:

```bash
keytool -genkey -v -keystore keystore/banana_escape_upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Then copy `android/key.properties.example` to `android/key.properties` and fill:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=../keystore/banana_escape_upload.jks
```

## 3. Build the artifact you will upload

Use Android App Bundle for Play Store uploads:

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

Output:

```text
build/app/outputs/bundle/release/app-release.aab
```

## 4. Fill Play Console sections in this order

1. Create app
2. Main store listing
3. App content
4. Data safety
5. Content rating
6. Target audience and content
7. Ads declaration
8. Pricing and distribution
9. Internal testing
10. Closed testing
11. Production

## 5. Suggested answers for the current MVP

These are only valid if the app stays as it is now.

- Login/account system: no
- User-generated content: no
- Ads SDK: no
- Analytics SDK: no
- Purchases/subscriptions: no
- Sensitive permissions: none
- Data sent off device by the app itself: none
- Internet-only web content: none
- Child-directed app: no, but child-friendly general audience tone is okay

If you add ads, analytics, cloud save, crash reporting, login, or online leaderboards, update Data safety before release.

## 6. Testing path

### Fast smoke test

- Use Internal App Sharing when you need a link quickly
- Good for immediate device installs
- Not a substitute for staged Play testing

### Internal testing

- Upload the release AAB to Internal testing first
- Add your own tester emails
- Validate install, update, icon, store listing, and crashes

### Closed testing

- Move to Closed testing after internal feedback
- Use this for balance, retention, session length, crash discovery, and store page review
- If your Play account is a newer personal account, check whether extra testing requirements apply before production

### Production

- Enable managed publishing if you want review approval before manually going live
- Roll out with a small percentage first if available for your account/app state

## 7. Pre-launch checklist for Banana Escape

- Swipe input feels correct on at least 2 real phones
- No clipped HUD on small screens
- Game over, retry, pause, and resume all work after repeated runs
- Skin purchase and equip flow works
- High score and total coins survive app restarts
- Sound toggle survives app restarts
- No debug text, temporary art notes, or placeholder package name remain
- Privacy policy URL is live
- App icon, feature graphic, and screenshots are final
- Keystore is backed up safely
- App bundle installs from Internal testing successfully

## 8. Release risks still worth checking

- Obstacle readability on lower brightness displays
- Frame pacing on weak Android devices
- Coin visibility against bright road backgrounds
- Review wording in store listing so the game does not look unfinished
- Store screenshots should show polished moments, not placeholder-like frames
