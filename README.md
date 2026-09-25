# 💰 Budget Ease – AI-Powered Budget Management for University Students

Budget Ease is an **AI-powered mobile budgeting application designed specifically for university students** to manage their personal finances more effectively.

The application allows users to record and manage their income and expenses, analyze spending patterns, visualize financial data, and receive personalized budget recommendations based on their financial behavior.

Budget Ease combines a **Flutter-based mobile application** with **Python-based machine learning components** to provide intelligent and personalized financial insights.

---

## 🎯 Problem

University students often face challenges when managing their personal finances due to limited or irregular income, changing expenses, and a lack of personalized budgeting guidance.

Traditional budgeting applications mainly focus on recording expenses, but they may not provide personalized recommendations based on an individual's spending behavior.

**Budget Ease addresses this problem by combining financial tracking with machine learning-based analysis and personalized budgeting recommendations.**

---

## 💡 Solution

Budget Ease provides a student-focused financial management platform that enables users to:

- Record and manage income
- Track daily expenses
- Categorize spending
- Review financial history
- Visualize spending patterns
- Analyze financial behavior
- Receive personalized budget recommendations
- Receive financial notifications and behavior tips

The application uses machine learning models to analyze user financial information and generate data-driven insights.

---

## ✨ Key Features

### 👤 User Account Management
- User registration and login
- Personalized user experience
- User profile management

### 💵 Income Management
- Record income sources
- Track income history
- Monitor available income

### 💳 Expense Tracking
- Record daily expenses
- Categorize expenses
- Organize spending by category
- Maintain expense history

### 📜 Financial History
- View previous income and expenses
- Review transaction history
- Monitor spending over time

### 📊 Analytics & Visualization
- Visualize spending patterns
- Category-wise expense analysis
- Financial summaries
- Interactive charts

### 📄 Financial Summary
- Generate financial summaries
- Review income and expense information
- Export financial information for personal reference

### 🔔 Notifications
- Budget-related notifications
- Financial reminders
- Personalized spending tips

### 🤖 Personalized Recommendations
- Personalized budget recommendations
- Spending behavior insights
- Data-driven financial guidance

---

# 🧠 Artificial Intelligence & Machine Learning

Budget Ease integrates machine learning components to provide personalized financial insights.

## 1. User Profile Identification

The system analyzes user financial information to identify:

- Income level
- Spending behavior
- Spender type

This helps the application provide more personalized financial recommendations.

---

## 2. Expense Prediction

An **LSTM (Long Short-Term Memory)** neural network is used to analyze temporal spending patterns and predict future category-wise expenses.

The model focuses on identifying patterns in historical spending behavior to support future budget planning.

---

## 3. Budget Recommendation

A machine learning-based recommendation component generates personalized budget allocations based on user financial characteristics and spending behavior.

---

## 4. Budget Adjustment

The system uses financial and behavioral information to support adaptive budget planning and provide recommendations based on changing spending patterns.

---

## 5. Financial Analytics

User financial data is transformed into visual and analytical insights to help users better understand their spending behavior and financial patterns.

---

# 📈 Machine Learning Model Performance

The machine learning components were evaluated during the research and development of the system.

| Model | Evaluation Metric | Result |
|---|---|---:|
| User Profile Identification | Income Type Accuracy | 82.43% |
| User Profile Identification | Spender Type Accuracy | 74.35% |
| Expense Prediction | R² Score | 0.8119 |
| Expense Prediction | RMSE | 0.01805 |
| Budget Adjustment | R² Score | 0.9483 |
| Budget Adjustment | MAE | Rs. 546.92 |
| Budget Recommendation | Accuracy | 89.6% |
| Budget Recommendation | F1 Score | 94% |

> These results represent the evaluation of the machine learning components developed as part of the project research.

---

# 🏗️ System Architecture

```text
┌──────────────────────────────────────┐
│          Flutter Mobile App          │
│                                      │
│  • Authentication                    │
│  • Income Management                 │
│  • Expense Tracking                  │
│  • Budget Management                 │
│  • Financial History                 │
│  • Analytics & Visualization         │
│  • Notifications                     │
└──────────────────┬───────────────────┘
                   │
                   │ HTTP / API
                   ▼
┌──────────────────────────────────────┐
│         Python Application            │
│                                      │
│  • API Services                      │
│  • Data Processing                   │
│  • ML Model Integration              │
└──────────────────┬───────────────────┘
                   │
                   ▼
┌──────────────────────────────────────┐
│       Machine Learning Layer         │
│                                      │
│  • User Profile Identification       │
│  • Expense Prediction                │
│  • Budget Recommendation             │
│  • Budget Adjustment                 │
└──────────────────────────────────────┘

Machine Learning Workflow

User Financial Data
        │
        ▼
Data Preprocessing
        │
        ▼
Feature Preparation
        │
        ▼
User Profile Identification
        │
        ▼
Spending Pattern Analysis
        │
        ▼
Expense Prediction
        │
        ▼
Budget Recommendation
        │
        ▼
Personalized Financial Insights

🛠️ Technology Stack
📱 Mobile Application
- Flutter
- Dart
⚙️ Backend & APIs
- Python
- Flask
- REST APIs
- HTTP
🤖 Machine Learning
- Python
- Scikit-learn
- TensorFlow
- Keras
- Random Forest
- LSTM
🗄️ Database
- SQLite
- sqflite
- sqflite_common_ffi
📊 Visualization
- FL Chart
- Interactive charts
- Financial data visualization
🧰 Development Tools
- Git
- GitHub
- Visual Studio Code
- Figma

📂 Project Structure
budget-ease-app/
│
├── android/                  # Android application configuration
├── assets/                   # Images, fonts and other resources
├── lib/                      # Flutter application source code
├── test/                     # Flutter tests
├── web/                      # Web configuration
│
├── app.py                    # Python API / ML application
│
├── *.pkl                    # Trained ML models and preprocessing artifacts
├── *.keras                  # Trained LSTM model
│
├── pubspec.yaml              # Flutter dependencies and configuration
├── analysis_options.yaml     # Dart analysis configuration
├── LICENSE                   # MIT License
└── README.md                # Project documentation

🎓 Academic Project
Project Name: Budget Ease – AI-Powered Budget Management for University Students
Project Type: Final Year Research & Software Development Project
University: Rajarata University of Sri Lanka

Team: Team Intellects
👥 Team Members
- Dhakshanyah Rajendra
- Daksagari Anandaraj
- M. M. Fathima Nuha
- M. S. Naseeha
- Thasanicka Sivaprasagam

🏆 Project Recognition
Budget Ease was developed and presented as a final-year research project.
The project received 3rd Place in the Final Year Research Project evaluation.

🔮 Future Improvements
Potential future improvements include:
- ☁️ Cloud-based data synchronization
- 🔐 Enhanced authentication and security
- 📊 Advanced financial analytics
- 🤖 Further improvement of machine learning models
- 🔄 More advanced real-time budget adaptation
- 🔔 Smarter personalized notifications
- 🌐 Expanded backend infrastructure
- 📱 Further cross-platform optimization

👩‍💻 Author
Dhakshanyah Rajendra
BSc in Information and Communication Technology
Rajarata University of Sri Lanka

🔗 Connect With Me
- 🌐 Portfolio: https://dhaksha28rajendra.github.io/my-portfolio/
- 💼 LinkedIn: https://www.linkedin.com/in/dhakshanyah-rajendra-3213b6315/
- 📧 Email: dhaksharajendra@gmail.com
