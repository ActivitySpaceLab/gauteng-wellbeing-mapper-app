---
layout: default
title: Gauteng Wellbeing Mapper
description: A mobile app for studying the relationship between place and mental wellbeing in South Africa
---

# Gauteng Wellbeing Mapper

A mobile app designed to help researchers understand the relationship between place and mental wellbeing in South African communities.

## 📱 For App Users

### Quick Start
- **[User Guide](USER_GUIDE.md)** - Complete guide to using the app
- **[Privacy Policy](PRIVACY.md)** - How we protect your data
- **[Download](https://github.com/ActivitySpaceLab/guateng-wellbeing-mapper-app/releases)** - Get the latest version

### Key Features
- **Private Mode**: Track your movements privately on your device
- **Research Mode**: Contribute anonymously to important wellbeing research
- **Location Tracking**: Background GPS tracking with full user control
- **Wellbeing Surveys**: Quick 2-3 minute surveys about your mood and environment
- **Data Export**: Full control over your personal data

### App Modes
The app offers two distinct modes to meet different user needs:

**🔒 Private Mode**
- All data stays on your phone
- No automatic sharing with researchers
- Perfect for personal movement tracking
- Export your own data anytime

**🔬 Research Mode** *(Gauteng residents only)*
- Anonymous, encrypted data sharing
- Contribute to Planet4Health study
- Bi-weekly wellbeing surveys
- Help advance wellbeing research

## 🔧 For Developers

### Documentation
- **[Developer Guide](DEVELOPER_GUIDE.md)** - Setup, build, and development instructions
- **[API Reference](API_REFERENCE.md)** - Complete API documentation
- **[Architecture](ARCHITECTURE.md)** - App structure and design patterns
- **[Flow Charts](FLOW_CHARTS.md)** - User flows and system diagrams

### Quick Setup
```bash
# Clone the repository
git clone https://github.com/ActivitySpaceLab/guateng-wellbeing-mapper-app.git

# Navigate to the project
cd guateng-wellbeing-mapper-app/wellbeing-mapper-app

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Key Technologies
- **Flutter 3.27.1** - Cross-platform mobile framework
- **Dart 3.3.1** - Programming language
- **Background Geolocation** - Location tracking
- **SQLite** - Local data storage
- **Material Design 3** - UI framework

### Research Features
- **[Notification System](NOTIFICATION_FEATURE_SUMMARY.md)** - Survey reminder system
- **[Research Features](RESEARCH_FEATURES_SUMMARY.md)** - Study participation tools
- **[Encryption Setup](ENCRYPTION_SETUP.md)** - Data security implementation
- **[Server Setup](SERVER_SETUP.md)** - Backend configuration

## 🔬 Research

This app is part of the **Planet4Health** study investigating how environmental factors affect mental wellbeing in Gauteng, South Africa.

### Study Goals
- Understand relationships between place and mental health
- Identify environmental factors that promote wellbeing
- Develop evidence-based interventions for communities
- Support policy decisions for healthier urban environments

### Participation
- **Voluntary**: All participation is completely voluntary
- **Anonymous**: No personal identifiers are collected
- **Secure**: All data is encrypted before transmission
- **Ethical**: Approved by university research ethics committees

### Principal Investigators
- **John Palmer**: john.palmer@upf.edu (Universitat Pompeu Fabra, Barcelona)
- **Linda Theron**: linda.theron@up.ac.za (University of Pretoria)
- **Caradee Wright**: Caradee.Wright@mrc.ac.za (South African Medical Research Council)

## 🛡️ Privacy & Security

We take your privacy seriously:

- **End-to-end encryption** for all research data
- **No personal identifiers** in location or survey data
- **Full user control** over data sharing and participation
- **GDPR compliant** data handling practices
- **University ethics approval** for all research activities

[Read our full Privacy Policy](PRIVACY.md)

## 📞 Support

### For Users
- **In-app**: Use "Report an Issue" in the app menu
- **Email**: Contact the research team through the app
- **Website**: Visit our [project website](http://activityspaceproject.com/)

### For Developers
- **Issues**: [GitHub Issues](https://github.com/ActivitySpaceLab/guateng-wellbeing-mapper-app/issues)
- **Discussions**: [GitHub Discussions](https://github.com/ActivitySpaceLab/guateng-wellbeing-mapper-app/discussions)
- **Pull Requests**: [Contributing Guidelines](DEVELOPER_GUIDE.md#contributing)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

---

### About the Activity Space Lab

The [Activity Space Lab](http://activityspaceproject.com/) studies how people move through their environments and how these movements affect health and wellbeing. Our interdisciplinary team combines expertise in geography, public health, psychology, and computer science to understand the complex relationships between place and human flourishing.

*Last updated: {{ site.time | date: "%B %Y" }}*
