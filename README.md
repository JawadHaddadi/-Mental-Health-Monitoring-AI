# Mental Health Monitoring Using AI

An intelligent mobile application designed to support mental well-being through Natural Language Processing (NLP), emotional analysis, psychological self-assessments, and personalized wellness recommendations.

## Project Overview

Mental Health Monitoring is an AI-powered mobile application developed to help users understand and monitor their emotional well-being.

The application integrates a locally deployed NLP model to analyze journal entries, identify emotional patterns, and provide personalized insights while keeping user data on-device.

## Key Features

- AI-Powered Emotional Analysis: Analyzes journal entries using a fine-tuned DistilBERT model.
- Mental Health Classification: Classifies text into five categories: Stress, Depression, Bipolar Disorder, Personality Disorder, and Anxiety.
- AI Chatbot: Provides supportive conversations through a context-aware conversation engine.
- Psychological Assessments: Includes PHQ-9, GAD-7, PSS-10, DASS-21, and WHO-5.
- Mood Tracking: Visualizes emotional patterns and progress over time.
- Wellness Exercises: Provides guided relaxation and evidence-based exercises.
- Privacy-Focused AI: Runs NLP inference locally using ONNX Runtime without relying on cloud-based AI APIs.

## AI and Machine Learning

The AI component is one of the core parts of this project.

### Model Architecture

- Base Model: DistilBERT.
- Architecture: Transformer-based language model.
- Tokenization: WordPiece.
- Model Deployment: ONNX.
- Inference Engine: ONNX Runtime.

### Model Training and Fine-Tuning

The model development process involved:

1. Using the GoEmotions dataset, containing approximately 58,000 Reddit posts with 28 emotion labels.
2. Fine-tuning the model using a Kaggle Mental Health dataset containing 5,525 social media posts.
3. Mapping emotion labels into five mental health categories.
4. Converting the trained model into ONNX format.
5. Integrating the model into the Flutter application for local inference.

### Classification Categories

- Stress.
- Depression.
- Bipolar Disorder.
- Personality Disorder.
- Anxiety.

### Model Evaluation

The project documentation reports an improvement from 25% accuracy before fine-tuning to 100% on an eight-example test set after fine-tuning and additional classification rules.

Note: These results are based on a small internal evaluation set and should not be interpreted as clinical validation or generalizable diagnostic accuracy.

## System Architecture

The application follows a four-layer architecture:

1. Presentation Layer: Flutter UI and application screens.
2. Business Logic Layer: Provider state management and conversation engine.
3. AI/NLP Layer: DistilBERT inference through ONNX Runtime and emotional pattern analysis.
4. Data Layer: SQLite local database.

All primary application processing and data storage are designed to operate locally on the device.

## Technologies Used

- Flutter: Mobile application development.
- Dart: Application programming language.
- Python: AI model development and training.
- DistilBERT: NLP and emotion classification.
- ONNX Runtime: Local model inference.
- SQLite: Local database.
- Provider: State management.
- WordPiece: Text tokenization.
- Figma: UI/UX design.

## Privacy and Safety

- Local NLP inference.
- Local SQLite data storage.
- No external AI API required for emotional analysis.
- Crisis detection and emergency resource guidance.
- Psychological assessments are screening tools, not clinical diagnoses.

## Project Limitations

- NLP emotion classification currently supports English text only.
- The application currently targets Android.
- The chatbot uses a predefined response library rather than generative AI.
- The system does not replace professional mental health evaluation.

## Future Improvements

- Arabic NLP support.
- iOS application deployment.
- Integration of an on-device generative language model.
- Further model evaluation using larger and more diverse datasets.

## Documentation

The full project documentation and presentation are available in the `docs/` directory.

## Disclaimer

This application is an educational and supportive tool. It is not intended to diagnose, treat, or replace professional mental health services.

## Contributors

Developed as a Computer Science graduation project at King Khalid University.
