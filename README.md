# Campus Safety App - Client Project
Status: Ongoing Development
A comprehensive safety application for educational campuses with real-time SOS alerts, incident reporting, and multi-level user management.

## 🚨 Overview

Campus Safety App is a Flutter-based mobile application designed to enhance security and emergency response within educational institutions. The app provides instant SOS functionality, incident reporting, and role-based access control for students, security personnel, administrators, and super admins.

## 👥 User Roles

### 🎓 Student
- Trigger emergency SOS alerts
- File complaints and reports
- View incident history
- Manage profile

### 🛡️ Security
- Receive real-time SOS alerts
- Monitor pending emergencies
- Coordinate response teams
- Track emergency history

### 👨‍💼 Admin
- Manage user accounts
- Monitor system activities
- View reports and analytics

### 🔧 Super Admin
- Full system control
- Role assignment
- System analytics
- Audit logs management
- College management

## ✨ Key Features

### 🚨 Emergency SOS System
- Instant emergency alert triggering
- Real-time notification to security teams
- Multiple SOS categories
- Location tracking

### 📋 Incident Management
- File and track complaints
- Report generation
- Status monitoring
- Historical data

### 🔐 Role-Based Access
- Multi-level user permissions
- Secure authentication
- Approval workflows
- Audit trails

### 📱 User-Friendly Interface
- Intuitive navigation
- Quick emergency access
- Real-time updates
- Responsive design

## 🛠️ Technology Stack

- **Frontend**: Flutter, Dart
- **Backend**: Firebase (Authentication, Firestore, Cloud Messaging)
- **State Management**: Provider/Riverpod
- **Notifications**: Firebase Cloud Messaging
- **Database**: Cloud Firestore

## 🚀 Quick Start

### Prerequisites
- Flutter SDK
- Firebase Project
- Android Studio / VS Code

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Varp17/nursingcollege.git
   cd campus_safety_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create Firebase project
   - Add Android/iOS apps
   - Download configuration files
   - Enable Authentication & Firestore

4. **Run the app**
   ```bash
   flutter run
   ```

## 📱 App Structure

```
lib/
├── admin/              # Admin features & user management
├── common/             # Shared components & navigation
├── models/             # Data models
├── screens/            # Main application screens
├── security/           # Security personnel features
├── services/           # Backend services & APIs
├── src/                # Core application setup
├── student/            # Student features & SOS
├── superadmin/         # Super admin management
├── utils/              # Constants & utilities
├── widgets/            # Reusable UI components
└── main.dart           # App entry point
```

## 🔥 Firebase Configuration

### Required Services
- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Messaging
- Firebase Storage (optional)

### Security Rules
Configure Firestore rules for role-based data access and ensure SOS alerts are readable by security personnel.

## 📋 Core Functionality

### Emergency Features
- One-tap SOS activation
- Real-time alert broadcasting
- Location sharing
- Emergency response tracking

### User Management
- Role-based access control
- User approval system
- Profile management
- Activity monitoring

### Reporting System
- Incident reporting
- Complaint tracking
- Analytics dashboard
- Audit logs

## 🎯 Usage

1. **Students**: Use SOS button for emergencies, file complaints
2. **Security**: Monitor alerts, respond to emergencies
3. **Admin**: Manage users, view reports
4. **Super Admin**: System configuration, role management

## 🤝 Contributing

1. Fork the project
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 📞 Support

Email - varunpatil0217@gmail.com

For support and queries, please contact the development team or create an issue in the repository.
