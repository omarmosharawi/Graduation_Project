# The RE: A Gamified Recycling Platform

## 📜 Introduction & Project Vision

This repository contains the backend source code for **The RE = Recycle + Reward**, a graduation project that aims to build a digital ecosystem that fundamentally changes how people interact with recycling. We are not just building an app; we are architecting a sustainable, habit-forming engine. Our mission is to make recycling an intuitive, rewarding, and integral part of daily life for millions.

This initiative is strategically positioned at the intersection of technology, environmental sustainability, and economic incentives, directly aligning with the forward-thinking goals of Egypt's Vision 2030 and Saudi Arabia's Vision 2030.

### The Problem

Public engagement in recycling is inconsistent. The process is often perceived as inconvenient, unrewarding, and lacking a clear feedback loop.

### Our Solution

A gamified, mobile-first platform that rewards users with tangible value (discounts) for their recycling efforts, facilitated by a network of accessible smart kiosks and an on-demand collection service.

## ✨ Features & Scope

### Minimum Viable Product (MVP)

  * **Android App**:
      * User Onboarding (Email/Phone) & Profile Management.
      * Unique QR Code for Kiosk Identification.
      * Real-time Points Balance & Transaction History.
      * Interactive Map to Locate Partner Kiosks.
      * Redeemable Rewards Catalog from Partner Venues.
  * **Landing Page**:
      * A clean, modern, single-page website.
      * Compelling explanation of the "How it Works" concept.
      * Links to download the Android app from the Google Play Store.
  * **Backend API**:
      * Secure RESTful API endpoints for all client-side operations.
      * Logic for user authentication, point calculation, and reward redemption.

### Proposed Features & Extended Vision

  * **Gamification & Ranking Layer**: A dual-point system, leaderboards, badges, and achievements to foster friendly competition.
  * **On-Demand Collection Service**: A premium feature allowing users to request a delegate to collect recyclables directly from their homes.
  * **Referral & Growth Program**: A system where users can invite friends and both parties receive bonus points.
  * **Community & Impact Hub**: An in-app dashboard showing the community's collective environmental impact.
  * **Corporate Social Responsibility (CSR) Portal**: A web portal for businesses to sign up as partners and manage their discount offerings.

Source: [The RE - User Stories](https://trello.com/1/cards/68ec1cb4bbcf8f4108543679/attachments/68f2405a7dc89905c0056c9c/download/The_RE_-_User_Stories.pdf)

## 🛠️ Technology Stack

| Category                   | Technology / Tool                                         |
| -------------------------- | --------------------------------------------------------- |
| **Project Management** | GitHub, Trello, Google Meet                               |
| **Product Design (UI/UX)** | Figma, Canva                                                     |
| **Frontend (Mobile)** | Flutter (Dart)                            |
| **Frontend (Web)** | Next.js (React Framework)                                 |
| **Backend** | Django (DRF), Celery                                      |
| **Database & Caching** | PostgreSQL, Redis                                         |
| **Services & Notifications**| Firebase Authentication, Firebase Cloud Messaging (FCM)                            |
| **Infrastructure & Deployment** | Hostinger, Nginx, Docker, GitHub Actions (CI/CD)          |
| **Monitoring Performance** | Prometheus, Grafana          |
| **API Testing & Security** | Postman, Swagger, Web/Mobile Endpoint Security Best Practices      |
| **Hardware** | ESP32-S, ESP32-CAM, Inductive (metal), IR (plastic), OLED 1.14" RGB, MG995 Servo      |

Source: [The RE - Unified Project Plan](https://trello.com/1/cards/68ec1b92ffb2f8e20c144889/attachments/68ec1bf19315f19435dae38e/download/The_ReWard_-_Unified_Project_Plan.pdf)

## 🚀 Getting Started

### Prerequisites

  * Python 3.11
  * Docker and Docker Compose
  * Pipenv
  * Flutter SDK 3.x

### Backend Installation

1.  **Clone the repository:**

    ```sh
    git clone https://github.com/omarmosharawi/Graduation_Project.git
    cd Graduation_Project
    ```

2.  **Create a virtual environment and install dependencies:**

    ```sh
    pipenv install
    pipenv shell
    ```

3.  **Create a `.env` file** in the `Backend` directory and add the necessary environment variables.

4.  **Run the development server using Docker:**

    ```sh
    docker-compose -f Backend/Docker/docker-compose.yml up --build
    ```

    The application will be available at `http://localhost:8000`.

## 📂 Project Structure

```
Backend/
├── apps/
│   ├── Users/        # Main application for user management and core logic
│   └── ...
├── config/
│   ├── settings/     # Django settings files
│   ├── django/       # Django configurations
│   └── ...
├── Docker/           # Docker-related files
├── manage.py
├── requirements.txt
└── ...
```
```
EcoSystem/
├── Mobile App/          # Flutter mobile application
│   ├── lib/
│   │   ├── app/         # Theme, routes, constants
│   │   ├── core/        # Services, widgets, utilities
│   │   └── features/    # Feature-based modules
│   └── ...
│
├── API/                 # REST API
│   ├── endpoints/       # API endpoint handlers
│   ├── config.php       # Configuration (credentials)
│   ├── firebase.php     # FCM & Firestore helpers
│   ├── index.php        # Main router
│   └── ...
│
└── 
```

## 📚 API Documentation

* **Postman Collection:** [The RE API Documentation](https://documenter.getpostman.com/view/38674073/2sB3QNqoqh)
* **Local Interactive Docs (Swagger):** When the development server is running, you can explore and test the endpoints directly from your browser at: [http://localhost:8000/en/api/docs/](http://localhost:8000/en/api/docs/)

## 🤝 Contributing

We welcome contributions to The RE project\! Please follow these steps to contribute:

1.  Fork the repository.
2.  Create a new branch (`git checkout -b feature/your-feature-name`).
3.  Make your changes.
4.  Commit your changes (`git commit -m 'Add some feature'`).
5.  Push to the branch (`git push origin feature/your-feature-name`).
6.  Open a pull request.

Please make sure to update tests as appropriate.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## 👥 Team

| Role                         | Member(s)    |
| ---------------------------- |--------------|
| **Product Manager & Team Leader** | Omar         |
| **Documentation & Architecture & Presentation** | Asmaa, Sherin, Clara  |
| **Product Designer (UI/UX)** | Clara, Sherin |
| **Web Frontend Developer** | Omar, Kirolos   |
| **Mobile Frontend Developer**| Abdelaziz, Ramez  |
| **Backend Developer** | Omar         |
| **DevOps Engineer** | Omar         |
| **Cybersecurity Specialist** | Kirolos         |

---
