# MediOrange 🍊

MediOrange is an intelligent medical assistant application built with Flutter. It leverages Google's Gemini AI to provide healthcare professionals and users with quick access to clinical guidelines, medical protocols, and procedural information based on standard authorities like WHO and CDC.

## ✨ Features

- **AI-Powered Medical Assistant**: Chat with "MedAssist", an AI specialized in medical procedures and protocols.
- **Clinical Guidelines**: Get answers based on standard clinical protocols (WHO, CDC).
- **Smart Context**: The AI is instructed to act as a medical expert and clarify its nature as an AI assistant.
- **Modern UI**: Clean, user-friendly interface with a distinctive orange theme.
- **Secure Configuration**: Uses environment variables for API key management.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **AI Model**: [Google Gemini](https://ai.google.dev/) (via `google_generative_ai`)
- **State Management**: `setState` (Simple and effective for current scope)
- **Configuration**: `flutter_dotenv`

## 🚀 Getting Started

Follow these steps to get the project up and running on your local machine.

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
- A Google Cloud project with the **Gemini API** enabled.
- An API Key for Gemini.

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Szymqn/MediOrange.git
   cd medi_orange
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables**
   Create a `.env` file in the root directory of the project and add your Gemini API key:
   ```env
   GEMINI_API_KEY=your_api_key_here
   ```

4. **Run the App**
   ```bash
   flutter run
   ```

## ⚠️ Disclaimer

**MediOrange is an AI assistant and does not replace professional medical advice, diagnosis, or treatment.** Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
