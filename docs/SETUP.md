# PutraSportHub - Setup Guide
**Last Updated:** January 7, 2025

This guide covers all setup and configuration required to run PutraSportHub.

---

## Table of Contents
1. [Firebase Setup](#firebase-setup)
2. [Cloudinary Setup](#cloudinary-setup-optional)
3. [API Keys Configuration](#api-keys-configuration)
4. [Running the App](#running-the-app)

---

## Firebase Setup

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: `putra-sport-hub` (or your preferred name)
4. Enable Google Analytics (optional)

### 2. Enable Services

#### Firestore Database
1. Go to **Firestore Database** → **Create database**
2. Choose **Production mode** (or Test mode for development)
3. Select location closest to your users
4. Click **Enable**

#### Authentication
1. Go to **Authentication** → **Get started**
2. Enable **Email/Password** provider
3. Click **Save**

### 3. Firestore Security Rules

Add these rules in **Firestore** → **Rules**:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Facilities are read-only for users
    match /facilities/{facility} {
      allow read: if true;
      allow write: if request.auth.token.role == 'ADMIN';
    }
    
    // Users can read/write their own profile
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Bookings: Users create, Admin/Owner reads
    match /bookings/{booking} {
      allow read: if request.auth.uid == resource.data.user_id || request.auth.token.role == 'ADMIN';
      allow create: if request.auth != null;
      allow update: if request.auth.token.role == 'ADMIN';
    }
    
    // Referee Jobs: Public read for students, restricted update
    match /referee_jobs/{job} {
      allow read: if request.auth.token.role == 'STUDENT';
      allow update: if request.auth.uid == resource.data.assigned_referee_id;
    }
  }
}
```

### 4. Add Firebase to Flutter

1. Install FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
```

2. Configure Firebase:
```bash
flutterfire configure
```

3. Select your Firebase project when prompted
4. This creates `lib/firebase_options.dart` automatically

---

## Cloudinary Setup (Optional)

This project uses **Cloudinary** for image storage (profile images).

## Why Cloudinary?

✅ **Free Tier**: 25 GB storage + 25 GB bandwidth/month  
✅ **No billing setup required** - works immediately  
✅ **Automatic CORS handling** - no configuration needed  
✅ **Image optimization** - automatic compression and format conversion  
✅ **Works on all platforms** - web, Android, iOS  

## Setup Steps

### 1. Create a Cloudinary Account

1. Go to [https://cloudinary.com/users/register/free](https://cloudinary.com/users/register/free)
2. Sign up for a free account (no credit card required)
3. Verify your email address

### 2. Get Your Credentials

After logging in, go to your **Dashboard**:
- **Cloud Name**: Found at the top of your dashboard (e.g., `my-cloud-name`)
- **API Key**: Click "Show" next to API Key in the dashboard
- **API Secret**: Click "Show" next to API Secret in the dashboard

### 3. Create an Upload Preset (Recommended)

An **upload preset** allows unsigned uploads without exposing your API secret in the app.

1. Go to **Settings** → **Upload** → **Upload presets**
2. Click **"Add upload preset"**
3. Configure:
   - **Preset name**: `putrasporthub_unsigned` (or any name you prefer)
   - **Signing mode**: **Unsigned** (important!)
   - **Folder**: `putrasporthub` (optional, for organization)
   - Click **Save**

### 4. Add Credentials to Your App

Open `lib/core/config/api_keys.dart` and add your credentials:

```dart
/// Cloudinary Cloud Name
static const String? cloudinaryCloudName = 'your-cloud-name-here';

/// Cloudinary API Key
static const String? cloudinaryApiKey = 'your-api-key-here';

/// Cloudinary Upload Preset (recommended for unsigned uploads)
static const String? cloudinaryUploadPreset = 'putrasporthub_unsigned';
```

**Note**: You can use either:
- **Option A (Recommended)**: Upload preset only (unsigned uploads) - safer, API secret not needed in app
- **Option B**: API Key + API Secret (signed uploads) - requires exposing API secret

### 5. Install Dependencies

Run:
```bash
flutter pub get
```

## Usage

The `StorageService` automatically handles:
- ✅ Profile image uploads → `uploadProfileImage()`

All images are stored in organized folders:
- `putrasporthub/profiles/{userId}/` - Profile images

**Note:** Cloudinary is currently only used for profile image uploads. Tournament sharing uses QR codes instead of image storage.

## Free Tier Limits

- **Storage**: 25 GB
- **Bandwidth**: 25 GB/month
- **Transformations**: Unlimited (within bandwidth limits)

For a demo/app prototype, this is more than sufficient!

## Troubleshooting

### Error: "Cloudinary not configured"
- Make sure you've added your credentials to `api_keys.dart`
- Verify your cloud name, API key, and upload preset are correct

### Error: "Invalid signature" (if using signed uploads)
- Ensure your API secret is correct
- Or switch to unsigned uploads using an upload preset (recommended)

### Upload fails with 401/403
- Check that your upload preset is set to **"Unsigned"** in Cloudinary Console
- Verify your API key is correct

## Resources

- [Cloudinary Documentation](https://cloudinary.com/documentation)
- [Upload Presets Guide](https://cloudinary.com/documentation/upload_presets)
- [Cloudinary Dashboard](https://console.cloudinary.com/)

---

## API Keys Configuration

This section covers all external API keys required for PutraSportHub.

### Overview

PutraSportHub uses the following external APIs:

| API | Purpose | Required | Free Tier Available |
|-----|---------|----------|---------------------|
| **Google Gemini API** | AI chatbot assistant | ✅ Yes | ✅ Yes (Free tier available) |
| **OpenWeatherMap API** | Weather checking for outdoor bookings | ⚠️ Optional | ✅ Yes (Free tier: 1,000 calls/day) |
| **Google Maps Static API** | Facility location map images | ⚠️ Optional | ✅ Yes (Free tier: $200/month credit) |
| **Cloudinary** | Image storage (profile images) | ⚠️ Optional | ✅ Yes (25 GB storage + 25 GB bandwidth/month) |

**Note:** All APIs have free tiers sufficient for development and testing.

---

### 1. Google Gemini API (Required)

**Purpose:** Powers the AI chatbot assistant with role-specific context.

**Used For:**
- AI chatbot responses
- Role-based assistance (Student, Public, Referee, Admin)
- App knowledge and feature guidance

#### Setup Steps:

1. **Get API Key:**
   - Go to [Google AI Studio](https://aistudio.google.com/app/apikey)
   - Sign in with your Google account
   - Click **"Create API Key"**
   - Copy your API key

2. **Add to App:**
   - Open `lib/core/config/api_keys.dart`
   - Find the `gemini` constant:
   ```dart
   static const String gemini = 'YOUR_API_KEY_HERE';
   ```
   - Replace `YOUR_API_KEY_HERE` with your API key

3. **Free Tier:**
   - Free tier includes generous quota
   - Model: `gemini-2.5-flash` (used in app)
   - Rate limits apply (check Google AI Studio dashboard)

---

### 2. OpenWeatherMap API (Optional)

**Purpose:** Weather checking to block outdoor bookings during rain.

**Used For:**
- Weather-based booking recommendations
- Outdoor facility availability (rain blocking)
- Weather warnings in booking flow

#### Setup Steps:

1. **Get API Key:**
   - Go to [OpenWeatherMap API](https://openweathermap.org/api)
   - Sign up for a free account
   - Verify your email
   - Go to **API Keys** section
   - Copy your API key (may take a few minutes to activate)

2. **Add to App:**
   - Open `lib/core/config/api_keys.dart`
   - Find the `openWeatherMap` constant:
   ```dart
   static const String openWeatherMap = 'YOUR_API_KEY_HERE';
   ```
   - Replace `YOUR_API_KEY_HERE` with your API key

3. **Free Tier:**
   - **1,000 API calls/day**
   - **60 calls/minute**
   - Current weather data
   - Sufficient for development and small-scale usage

**Note:** If not configured, the app will still work but weather checking will be disabled (all outdoor bookings allowed).

---

### 3. Google Maps Static API (Optional)

**Purpose:** Display static map images showing facility locations in booking details.

**Used For:**
- Facility location maps in booking details
- Visual representation of venue locations

#### Setup Steps:

1. **Enable API:**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select existing
   - Enable **Maps Static API**:
     - Go to **APIs & Services** → **Library**
     - Search for "Maps Static API"
     - Click **Enable**

2. **Get API Key:**
   - Go to **APIs & Services** → **Credentials**
   - Click **Create Credentials** → **API Key**
   - Copy your API key
   - (Optional) Restrict API key to "Maps Static API" for security

3. **Add to App:**
   - Open `lib/core/config/api_keys.dart`
   - Find the `googleMapsStatic` constant:
   ```dart
   static const String googleMapsStatic = 'YOUR_API_KEY_HERE';
   ```
   - Replace `YOUR_API_KEY_HERE` with your API key

4. **Free Tier:**
   - **$200/month free credit**
   - Static maps: $0.002 per request
   - Sufficient for ~100,000 requests/month free

**Note:** If not configured, booking details will show facility information without map images.

---

### 4. Cloudinary (Optional)

**Purpose:** Image storage for profile pictures.

**Used For:**
- User profile image uploads
- Profile picture storage and optimization

**Setup:** See [Cloudinary Setup](#cloudinary-setup-optional) section above.

---

## Adding API Keys to the App

All API keys are configured in `lib/core/config/api_keys.dart`.

### File Structure:

```dart
class ApiKeys {
  ApiKeys._(); // Prevent instantiation

  // Google Maps Static API Key
  static const String googleMapsStatic = 'YOUR_KEY_HERE';

  // Google Gemini API Key
  static const String gemini = 'YOUR_KEY_HERE';

  // Cloudinary Configuration
  static const String cloudinaryCloudName = 'YOUR_CLOUD_NAME';
  static const String cloudinaryApiKey = 'YOUR_API_KEY';
  static const String cloudinaryApiSecret = 'YOUR_API_SECRET';

  // OpenWeatherMap API Key
  static const String openWeatherMap = 'YOUR_KEY_HERE';
}
```

### Verification:

The app includes helper methods to check API key configuration:

```dart
// Check if all required keys are configured
ApiKeys.areAllKeysConfigured

// Get list of missing keys
ApiKeys.missingKeys

// Get feature status (which APIs are enabled)
ApiKeys.featureStatus
```

---

## Running the App

After configuring all API keys:

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Run the app:**
   ```bash
   flutter run
   ```

3. **Verify API configuration:**
   - Check console logs for API configuration status
   - Test features that use APIs:
     - AI chatbot (Gemini)
     - Weather warnings (OpenWeatherMap)
     - Facility maps (Google Maps)
     - Profile image uploads (Cloudinary)

---

## Troubleshooting

### API Key Errors

**Error: "API key not configured"**
- Verify you've added the API key to `api_keys.dart`
- Check for typos or extra spaces
- Restart the app after adding keys

**Error: "Invalid API key"**
- Verify the API key is correct
- Check if API key has been activated (some APIs require activation)
- Verify API restrictions (if any) in service dashboard

**Error: "Quota exceeded"**
- Check your API usage in service dashboard
- Free tier limits may have been reached
- Wait for quota reset (usually daily/monthly)

### Google Gemini API

- **Model not found:** Ensure you're using `gemini-2.5-flash` (or update model name in code)
- **Rate limits:** Free tier has rate limits - check Google AI Studio dashboard

### OpenWeatherMap API

- **API key not activated:** New keys may take a few minutes to activate
- **Daily limit:** Free tier allows 1,000 calls/day

### Google Maps Static API

- **API not enabled:** Ensure "Maps Static API" is enabled in Google Cloud Console
- **Billing:** Free tier requires billing account (but uses free credit first)

---

## Resources

- [Google AI Studio (Gemini)](https://aistudio.google.com/app/apikey)
- [OpenWeatherMap API Documentation](https://openweathermap.org/api)
- [Google Maps Static API Documentation](https://developers.google.com/maps/documentation/maps-static)
- [Cloudinary Documentation](https://cloudinary.com/documentation)
