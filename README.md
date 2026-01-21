# PutraSportHub 🏟️

**Campus Sports Ecosystem for Universiti Putra Malaysia (UPM)**

A comprehensive Flutter mobile application that digitizes UPM's sports facility management, gig economy for referees, tournament management, and academic merit integration.

![Flutter](https://img.shields.io/badge/Flutter-3.7+-02569B?style=flat-square&logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Firestore-FFCA28?style=flat-square&logo=firebase)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

---

## 📊 Current Status

**Overall Completion:** ~95%  
**Core Features:** 100% Complete ✅  
**Status:** Ready for Demo/Beta Testing ✅

### What's Working
- ✅ **Complete booking system** (simplified 3-step flow)
- ✅ **Split bill functionality** for normal bookings (students only, sport-based participant limits)
- ✅ **Unified time slot availability** (normal bookings + tournaments shown together)
- ✅ **Tournament system fully integrated** (creation, joining, management)
- ✅ **Tournament Hub** with smart tabs (Discover, My Active, History)
  - Discover: Browse open tournaments
  - My Active: Organizing/Participating with role filters
  - History: Past tournaments you organized or participated in
- ✅ **Tournament sharing** with QR codes (WhatsApp, Twitter, Email)
- ✅ **Join tournaments** via QR code scanner or share code
- ✅ **Split bill booking sharing** with QR codes and deep links
- ✅ **In-app notifications** for split bill events (join, paid, confirmed, left)
- ✅ **Referee marketplace** (SukanGig) with escrow payments
- ✅ **AI chatbot** with role-specific context
- ✅ **Merit points system** (GP08 integration)
- ✅ **Payment/wallet system** (SukanPay)
- ✅ **Admin dashboard**

---

## ✨ Key Features

### 🏆 Core Features

1. **Smart Facility Booking**
   - Tiered pricing (Student vs Public rates)
   - **Split bill functionality** (students only)
     - Sport-based participant limits (Football: max 22, Futsal: max 12, Badminton: max 8, Tennis: max 4)
     - Organizer pays only their share initially
     - Auto-confirmation when all participants paid
     - Proportional refunds on cancellation
     - Share booking via QR code or team code
   - **Unified time slot availability** (normal bookings + tournaments)
     - Visual indication of booked slots
     - Prevents double-booking
   - Weather-adaptive booking for outdoor facilities
   - Friday prayer time blocking
   - Multiple booking patterns: Session, Hourly, Inventory

2. **Tournament Management**
   - Tournament creation wizard
   - **Tournament Hub** with smart tabs:
     - **Discover:** Browse open tournaments (excludes your own)
     - **My Active:** Your organizing/participating tournaments
       - Role filters: All, Organizing, Participating
       - Icon-first segmented filter chips
     - **History:** Past tournaments you organized or participated in
   - **Sticky sport filter bar** across all tabs
   - Sport filtering (All Sports, Football, Futsal, Badminton, Tennis)
   - QR code sharing (multi-platform: WhatsApp, Twitter, Email)
   - Join tournaments via QR code scanner or share code
   - Team registration and bracket management
   - Automatic status updates (registration → in-progress → completed)
   - Firestore transactions prevent race conditions

3. **SukanGig (Referee Marketplace)**
   - Gig economy for certified student referees
   - Course-based certification (QKS codes)
   - QR code venue check-in
   - Escrow-based payment protection

4. **MyMerit (Academic Integration)**
   - UPM Housing Merit System (GP08) integration
   - Automatic point tracking
   - PDF transcript generation

### 🤖 AI Features

- **AI Chatbot** ✅ - Role-specific context-aware help assistant
- **Smart Weather-Based Booking** - OpenWeatherMap integration

### 🏃 Supported Sports

| Sport | Facilities | Booking Type |
|-------|------------|--------------|
| ⚽ Football | Stadium UPM, Padang A-E (6 fields) | 2-Hour Sessions |
| 🥅 Futsal | Gelanggang Futsal A-D (4 courts) | 2-Hour Sessions |
| 🏸 Badminton | Dewan Serbaguna (8 courts) | Hourly + Court Selection |
| 🎾 Tennis | Gelanggang Tenis UPM (14 courts) | Hourly + Court Selection |

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.7+
- Firebase project
- API keys (see Setup Guide)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd putraSportHub
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   ```bash
   flutterfire configure
   ```

4. **Add API Keys**
   - Edit `lib/core/config/api_keys.dart`
   - Add Gemini API key (for chatbot)
   - Add Cloudinary credentials (optional, for profile images)

5. **Run the app**
   ```bash
   flutter run
   ```

For detailed setup instructions, see [docs/SETUP.md](docs/SETUP.md).

---

## 📚 Documentation

All documentation has been organized in the `docs/` folder:

- **[docs/PROJECT.md](docs/PROJECT.md)** - Comprehensive project documentation (architecture, features, status)
- **[docs/SETUP.md](docs/SETUP.md)** - Complete setup guide (Firebase, Cloudinary, API keys)
- **[docs/REFERENCE.md](docs/REFERENCE.md)** - Domain knowledge, business rules, and user flows

### Historical Documentation
Historical planning and implementation documents are archived in [docs/archive/](docs/archive/).

---

## 🏗️ Technology Stack

- **Frontend:** Flutter 3.7+ (Dart)
- **Backend:** Firebase (Firestore, Auth)
- **Image Storage:** Cloudinary (25 GB free tier, optional)
- **State Management:** Riverpod 2.6+
- **Routing:** GoRouter 14.8+
- **External APIs:**
  - Google Gemini API (AI chatbot)
  - OpenWeatherMap API (weather - optional)
  - Google Maps Static API (facility maps)

---

## 📁 Project Structure

```
lib/
├── core/              # Config, constants, navigation, theme, utils, widgets
├── features/          # Feature-based modules (auth, booking, tournament, etc.)
├── services/          # Business logic services
└── providers/         # Riverpod providers
```

For detailed project structure, see [docs/PROJECT.md](docs/PROJECT.md).

---

## 👥 User Roles

- **Students** (`@student.upm.edu.my`) - Full access (tournaments, merit, referees)
- **Public Users** - Basic booking access
- **Referees** - Students with certification badges
- **Admins** - System management

---

## 🎯 Key Differentiators

1. **Real-World Application** - Solves actual UPM sports management issues
2. **Complete Ecosystem** - Full sports lifecycle (booking → tournaments → referees → merit)
3. **AI Integration** - Practical AI usage (chatbot for help)
4. **Academic Integration** - Merit points (GP08) integration
5. **Multi-User Types** - Different experiences for different user roles
6. **Modern UI/UX** - Glassmorphic design, smooth animations

---

## 📞 Testing Accounts

- Student: `ali@student.upm.edu.my` / `Password123`
- Student (Referee): `haziq@student.upm.edu.my` / `Password123`
- Public: `public@example.com` / `Password123`
- Admin: `admin@upm.edu.my` / `AdminPass123`

---

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Universiti Putra Malaysia (UPM) Pusat Sukan
- UPM Housing & Transportation Department (GP08 Guidelines)
- Flutter & Firebase Communities

---

**Built with 💚 for UPM Sports Community**

*PutraSportHub - Where Campus Sports Meet Technology*
