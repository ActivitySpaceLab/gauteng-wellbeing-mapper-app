---
layout: default
title: Wellbeing Mapper
description: A mobile app for studying mental wellbeing in environmental & climate context
---

Welcome to the **Wellbeing Mapper** documentation website. Wellbeing Mapper is a mobile app for studying mental wellbeing in environmental & climate context. It has been developed as part of the [Planet4Health project](https://planet4health.eu), funded by the European Union. The app will soon be used for research involving volunteers in Guateng, South Africa, and Barcelona, Spain. It is currently in beta testing.

This site contains information aimed at app users (i.e. research volunteers and anyone who simply wants to use the app for their), , 

## 📱 For App Users

### Quick Start
- **[User Guide](USER_GUIDE.md)** - Complete guide to using the app
- **[Privacy Policy](PRIVACY.md)** - How we protect your data
- **[Download](https://github.com/ActivitySpaceLab/guateng-wellbeing-mapper-app/releases)** - Get the latest version

### Key Features
- **Private Mode**: Track where you spend your time privately on your device
- **Research Mode**: Contribute anonymously to important wellbeing research
- **Location Tracking**: Background GPS tracking with full user control
- **Wellbeing Surveys**: Quick 2-3 minute surveys about your mental wellbeing
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

This app is part of the **Planet4Health** study investigating how environmental factors affect mental wellbeing. This version of the app has been designed specifically for the case study in Gauteng, South Africa.

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
- **Linda Theron**: linda.theron@up.ac.za (University of Pretoria)
- **Caradee Wright**: Caradee.Wright@mrc.ac.za (South African Medical Research Council)
- **John Palmer**: john.palmer@upf.edu (Universitat Pompeu Fabra, Barcelona)


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
- **Website**: Visit the [Planet4Health website](https://planet4health.eu)

### For Developers
- **Issues**: [GitHub Issues](https://github.com/ActivitySpaceLab/guateng-wellbeing-mapper-app/issues)
- **Discussions**: [GitHub Discussions](https://github.com/ActivitySpaceLab/guateng-wellbeing-mapper-app/discussions)
- **Pull Requests**: [Contributing Guidelines](DEVELOPER_GUIDE.md#contributing)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

---

### About the Planet4Health Project

The [Planet4Health Project](https://planet4health.eu) is a Horizon Europe research initiative focused on translating science into policy through a multisectoral approach to adaptation and mitigation of adverse effects of vector-borne diseases, environmental pollution, and climate change on planetary health.

**Mental Wellbeing in Environmental & Climate Context**

Traditional studies on environmental and climate changes have predominantly focused on physical health. However, these changes also contribute to rising mental health and psychosocial issues linked to socio-economic threats, including emotional distress and exacerbation of existing mental health conditions—often referred to as climate-related psychological distress.

This case study aims to collect and analyze mental wellbeing data alongside environmental data to develop a comprehensive understanding of mental health impacts. The project seeks to create integrated risk monitoring systems, map environmental hotspots, and provide solutions for better preparedness and response capacity.

*Last updated: {{ site.time | date: "%B %Y" }}*
