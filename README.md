<div align="center">

# 🌊 ReUsea: Sustainable Eco-Commerce Mobile Platform

![Platform](https://img.shields.io/badge/Platform-Flutter_Cross--Platform-blue?style=for-the-badge&logo=flutter&logoColor=white)
![Backend](https://img.shields.io/badge/Backend-Firebase_Infrastructure-orange?style=for-the-badge&logo=firebase&logoColor=white)
![Target](https://img.shields.io/badge/Focus-Sustainability_%7C_Circular_Economy-green?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Completed-success?style=for-the-badge)

<p align="center">
  <strong>A mobile marketplace prototype built to champion waste upcycling and support sustainable economic flows.</strong>
</p>

[About Project](#-about-project) • [Key Features](#-core-platform-features) • [Tech Stack](#-technology-matrix) • [Repository Structure](#-repository-structure) • [UI Showcase](#-user-interface-documentation)

</div>

---

## 📖 About Project

**ReUsea** is a sustainability-focused mobile application prototype developed using **Flutter** and **Firebase**. The platform is specifically designed to tackle environmental challenges by empowering communities to trade upcycled products, second-hand goods, and materials supporting a circular economy. 

Backed by rigorous foundational planning—including a Business Model Canvas (BMC), SWOT Analysis, and detailed operational logbooks—ReUsea bridges eco-conscious merchants with consumers looking to minimize their carbon footprint.

### 🎯 Key Objectives
- ♻️ **Circular Economy:** Creating an accessible hub for upcycled arts, crafts, and repurposed daily items.
- 📱 **Cross-Platform Delivery:** Implementing clean, fluid reactive state management for seamless Android and iOS experiences.
- ⚡ **Real-Time Synergy:** Utilizing cloud infrastructure to handle dynamic media feeds, live in-app messaging, and automated order workflows.

---

## 🌎 Core Platform Features

### 1. Unified User Flow & Authentic Identity
- **Secure Gateways (`login_page.dart`, `register_page.dart`):** Streamlined user onboarding backed by secure account provisioning.
- **OTP Verification (`otp_page.dart`):** An additional layer of verification to secure user actions and transactions.
- **Personal Workspace (`profile_page.dart`, `edit_profile_page.dart`):** Comprehensive user profiles showing individual eco-impact metrics and custom avatars.

### 2. Marketplace & Eco-Commerce Management
- **Product Lifecycle Controls (`sell_item_page.dart`, `edit_items_page.dart`):** Sellers can list upcycled inventory with photo uploads, category tagging, and pricing tiers.
- **Dynamic Exploration (`home_page.dart`, `detail_page.dart`):** A beautiful masonry item card feed with intuitive searching and item-specific wishlists.
- **Basket & Checkout Mechanics (`cart_page.dart`, `checkout_page.dart`):** Native checkout flow integrating integrated item summary calculations and automated delivery distance assessment.

### 3. Interactive Social & Feedback Channels
- **Live Negotiator (`chat_page.dart`, `chat_detail_page.dart`):** Real-time, instant text streams between prospective buyers and green vendors.
- **Quality Assurance Loop (`feedback_page.dart`, `rating_modal.dart`):** In-app modular rating pop-ups to review items and preserve marketplace transparency.
- **Location Primitives (`map_picker_page.dart`):** Interactive map selection module to pick precise drop-off and delivery locations.

---

## 🛠️ Technology Matrix

| Layer | Component Technology / Stack Tools |
| :--- | :--- |
| **Frontend Framework** | Flutter SDK (Dart Language Architecture) |
| **State & Lifecycle** | Reactive Flutter Stateful Widget Layouts & Page Routing |
| **Backend & Services** | Firebase Authentication, Cloud Firestore Database |
| **Native Tooling** | Gradle, CocoaPods, CMake System Configurations |
| **Development IDE** | VS Code, Android Studio, Xcode Core Tools |

---

## 📂 Repository Structure

```text
ReUsea/
│
├── 📁 android/             # Android native native layer gradle & service properties
├── 📁 ios/                 # iOS native deployment runner & workspace assets
├── 📁 linux/               # Linux CMake native compile trees
├── 📁 macos/               # macOS target app architecture resources
├── 📁 windows/             # Windows OS runner setup frameworks
├── 📁 web/                 # Web container layout configurations (manifest & favicon)
│
├── 📁 assets/              # Static graphic assets & item profile placeholders
│   └── 📁 images/          # Platform imagery (iphone, magiccom, vanity showcases)
│
├── 📁 lib/                 # Core cross-platform Dart code engine
│   ├── 📄 main.dart        # Main gateway initializing layout configurations
│   ├── 📄 firebase_options.dart # Generated production Firebase parameters
│   │
│   ├── 📁 models/          # Structured data entities (Achievement, Checkout, Product)
│   ├── 📁 services/        # Firebase network abstractors (Auth, Database, Delivery)
│   ├── 📁 utils/           # Utility helpers (Theme parameters, Page transitions)
│   ├── 📁 widgets/         # Shared modular UI buttons and dialog cards (Rating modal)
│   └── 📁 pages/           # High-fidelity app layouts (Cart, Chat, Home, Sell, Maps)
│
└── 📄 pubspec.yaml         # Package configurations, asset paths, and SDK versions
```

## 📸 User Interface Documentation

**Active Eco-Commerce Marketplace Feed**

Below is a visual layout preview of the ReUsea mobile ecosystem interface structure:
<div align="center">
<img width="30%" alt="ReUsea Mobile Interface Preview" src="https://github.com/user-attachments/assets/68155d2d-4950-426b-a845-1a0257ecd295" />
<img width="30%" alt="image" src="https://github.com/user-attachments/assets/1449209f-60a8-49dc-9a92-514fe3971a95" />
<img width="30%" alt="image" src="https://github.com/user-attachments/assets/8f884996-23f9-4982-8101-1b4d4af158c1" />
<img width="30%" alt="image" src="https://github.com/user-attachments/assets/2ffdd830-86a5-44df-9779-89a64e572a79" />
</div>


## 🎓 Author

**Cesya Aulia Ramadhani**

Applied Science Undergraduate Student in Management Informatics — Universitas Negeri Surabaya
