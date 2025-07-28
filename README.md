# **Wellbeing Mapper** 🧪 Beta Version

## What is Wellbeing Mapper?

Wellbeing Mapper is a privacy-focused mobile application that lets you map your mental wellbeing in environmental & climate context. 

### Current Beta Status
This is currently a **beta testing version** with two available modes:

- **🔒 Private Mode**: Use the app for personal wellbeing tracking - all data stays on your device
- **🧪 App Testing Mode**: Test all research features safely - no real research data is collected

The full research participation mode will be available in the next release for actual study participants in Gauteng, South Africa.

### About the Research (Coming in Full Release)
When released, the app will enable participants to map the routes they take and places where they spend time while tracking their mental wellbeing through surveys and digital diary entries. Research participants will be able to securely share this information with researchers studying how environmental and climate factors impact mental wellbeing.

This application is part of a case study in the [Planet4Health project](https://planet4health.eu), a Horizon Europe research initiative focused on translating science into policy for planetary health. The case study specifically addresses "[Mental wellbeing in environmental & climate context](https://planet4health.eu/mental-wellbeing-in-environmental-climate-context/)" - an emerging field that recognizes how environmental and climate changes contribute to rising mental health and psychosocial issues.

### About the Planet4Health Case Study

Traditional studies on environmental and climate change impacts have predominantly focused on physical health. However, these changes also contribute to a range of mental health disorders from emotional distress to the exacerbation of existing mental health conditions, often referred to as climate-related psychological distress.

This case study aims to:
- Collect and analyze mental wellbeing data alongside environmental data
- Develop comprehensive understanding of mental health impacts from environmental factors
- Create integrated risk monitoring systems
- Map environmental hotspots affecting mental health
- Provide solutions for better preparedness and response capacity

[![CI tests](https://github.com/ActivitySpaceLab/guateng-wellbeing-mapper-app/actions/workflows/CI.yml/badge.svg)](https://github.com/ActivitySpaceLab/guateng-wellbeing-mapper-app/actions/workflows/CI.yml)
[![drive_test iOS](https://github.com/ActivitySpaceLab/guateng-wellbeing-mapper-app/actions/workflows/drive-ios.yml/badge.svg)](https://github.com/ActivitySpaceLab/guateng-wellbeing-mapper-app/actions/workflows/drive-ios.yml)
[![drive_test Android](https://github.com/ActivitySpaceLab/guateng-wellbeing-mapper-app/actions/workflows/drive-android.yml/badge.svg)](https://github.com/ActivitySpaceLab/guateng-wellbeing-mapper-app/actions/workflows/drive-android.yml)
[![codecov](https://codecov.io/gh/ActivitySpaceLab/guateng-wellbeing-mapper-app/graph/badge.svg?token=CK8N6GEWKR)](https://codecov.io/gh/ActivitySpaceLab/guateng-wellbeing-mapper-app)
[![Documentation](https://img.shields.io/badge/docs-available-brightgreen.svg)](https://github.com/ActivitySpaceLab/guateng-wellbeing-mapper-app/tree/main/docs)

## Prerequisites

**Important**: This project requires **Flutter 3.27.1** with **Dart 3.6.0** specifically. The app will not compile with other versions due to dependency constraints.

### Using FVM (Recommended)
```bash
# Install FVM
dart pub global activate fvm

# Use the correct Flutter version
fvm use 3.27.1

# Verify version
fvm flutter --version
```

### Without FVM
Ensure you have Flutter 3.27.1 installed:
```bash
flutter --version
# Should show: Flutter 3.27.1 • Dart 3.6.0
```

## How to contribute
Do you want to contribute?

Feel free to fork our repository, create a new branch, make your changes and submit a pull request(*). We'll review it as soon as possible and merge it.

(*)Before opening the pull request, please run the commands `fvm flutter analyze` and `fvm flutter test` locally (or `flutter analyze` and `flutter test` if not using FVM) to ensure that your PR passes all the tests successfully in our continuous integration (CI) workflow.

It would be awesome if you assign yourself to an existing task or you open a new issue in [Github Issues](https://github.com/ActivitySpaceLab/guateng-wellbeing-mapper-app/issues), to keep other contributors informed on what you're working on.

If this project is useful for you, please consider starring this repository and giving us 5 stars on the app stores to give us more visibility.

## Contributors
- Otis Johnson
    - [github.com/StuffJoy](http://github.com/StuffJoy)
- Pablo Galve Millán
    - [github.com/pablogalve](https://github.com/pablogalve)
    - [linkedin.com/in/pablogalve/](https://www.linkedin.com/in/pablogalve/)
- John R.B. Palmer
    - [github.com/johnpalmer](https://github.com/johnpalmer)

## Beta Testing Documentation

### For Beta Testers
- **[Beta User Guide](docs/BETA_USER_GUIDE.md)** - Complete guide for beta testing the app
- **[Getting Started](docs/BETA_USER_GUIDE.md#getting-started)** - How to choose modes and test features
- **[Feedback Guidelines](docs/BETA_USER_GUIDE.md#how-to-provide-feedback)** - How to report issues and suggestions

### For Developers
- **[Beta Testing Guide](docs/BETA_TESTING_GUIDE.md)** - Release preparation and beta configuration
- **[Developer Guide](docs/DEVELOPER_GUIDE.md)** - Technical documentation and architecture
- **[App Mode System](docs/DEVELOPER_GUIDE.md#app-mode-system)** - Understanding beta vs. research modes

## Features

### Current Beta Features
* **🔒 Private Mode**: Track your mental wellbeing privately on your device
* **🧪 App Testing Mode**: Test all research features safely with no real data collection
* **📍 Location Tracking**: Background GPS tracking with full user control
* **📝 Wellbeing Surveys**: Quick 2-3 minute mental wellbeing assessments
* **🔔 Smart Notifications**: Bi-weekly survey reminders with testing intervals available
* **🎛️ Testing Tools**: Comprehensive testing features for beta validation
* **🔒 Privacy-First Design**: All beta data stays on your device
* **🎨 Intuitive Interface**: Easy-to-use design with clear mode explanations

### Future Research Features (Coming in Full Release)
* **🔬 Research Participation**: Real study participation with participant codes
* **🔐 End-to-End Encryption**: Military-grade RSA+AES encryption for research data
* **📊 Research Data Upload**: Secure bi-weekly uploads to research servers
* **🌍 Multi-Site Support**: Barcelona, Spain and Gauteng, South Africa studies
* **📋 Consent Management**: Full research consent and information sheets
* **🎯 Climate-Health Research**: Contribute to understanding climate psychological impacts

## Beta Testing vs. Future Research

### Current Beta Status
This version allows you to:
- ✅ Test all app features safely
- ✅ Experience research workflows without data collection
- ✅ Provide feedback on user experience
- ✅ Use privately for personal wellbeing tracking

### Future Research Participation (Coming Soon)
When the research version is released:
- 🔬 Real study participation in Gauteng, South Africa
- 📋 Participant codes and consent processes
- 🔐 Encrypted data sharing with research teams  
- 📊 Contribute to climate-mental health research

### For Beta Testers
Your feedback helps us:
- Improve user experience before research launch
- Validate technical functionality
- Ensure privacy and security features work correctly
- Create better documentation and support

## Download the Beta Version
For more information about the Planet4Health project, please visit the [Planet4Health website](https://planet4health.eu) and learn about the [Mental wellbeing in environmental & climate context case study](https://planet4health.eu/mental-wellbeing-in-environmental-climate-context/).

- [Google Play (Android)](http://play.google.com/store/apps/details?id=edu.princeton.jrpalmer.asm).
- Apple Store (iOS) (Coming soon)
- [Github Releases (Android)](https://github.com/ActivitySpaceLab/guateng-wellbeing-mapper-app/releases).

## About Planet4Health

Planet4Health is a Horizon Europe research project focused on "Translating Science into Policy: A Multisectoral Approach to Adaptation and Mitigation of Adverse Effects of Vector-Borne Diseases, Environmental Pollution and Climate Change on Planetary Health." The project is part of the Planetary Health Cluster, which includes five Horizon Europe projects working together to address climate change and health challenges.

**Funding**: This project is funded by the European Union under the Horizon Europe programme. Views and opinions expressed are however those of the author(s) only and do not necessarily reflect those of the European Union or the European Health and Digital Executive Agency (HADEA).

## License
This repository contains the source code development version of Wellbeing Mapper, developed as part of the Planet4Health project case study on mental wellbeing in environmental & climate context.

This project is licensed under the [GNU GENERAL PUBLIC LICENSE](https://github.com/ActivitySpaceLab/guateng-wellbeing-mapper-app/blob/master/LICENSE)

Copyright 2011-2020 John R.B. Palmer 
Copyright 2021-2023 John R.B. Palmer and Pablo Galve Millán
Copyright 2021-2023 John R.B. Palmer, Pablo Galve Millán, and Otis Johnson

 
Wellbeing Mapper is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

Wellbeing Mapper is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see http://www.gnu.org/licenses.
