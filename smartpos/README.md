# SmartPOS - Point of Sale System

A complete POS (Point of Sale) system with mobile and web support built with Flutter frontend and FastAPI backend.

## Project Structure

### Backend (FastAPI)

```
smartpos/backend/
├── main.py (FastAPI app)
├── models.py (SQLAlchemy models)  
├── database.py (DB connection)
├── schemas.py (Pydantic schemas)
├── auth.py (authentication utilities)
└── requirements.txt
```

### Frontend (Flutter)

```
smartpos/frontend/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── user.dart
│   │   └── product.dart
│   ├── services/
│   │   └── api_service.dart
│   ├── providers/
│   │   └── auth_provider.dart
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── dashboard_screen.dart
│   └── l10n/
│       ├── app_en.arb
│       └── app_hi.arb
└── pubspec.yaml
```

## Getting Started

### Setting up the Backend

1. Create a Python virtual environment and install dependencies:
```bash
cd smartpos/backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

2. Run the FastAPI server:
```bash
uvicorn main:app --reload
```

3. The server will be available at http://127.0.0.1:8000 and the API documentation at http://127.0.0.1:8000/docs

### Setting up the Frontend

1. Make sure you have Flutter installed (https://flutter.dev/docs/get-started/install)

2. Install dependencies:
```bash
cd smartpos/frontend
flutter pub get
```

3. Make sure the API URL in `lib/services/api_service.dart` points to your backend server

4. Run the app:
```bash
# For Web
flutter run -d chrome

# For Android
flutter run -d android
```

## Features

- User authentication with JWT tokens
- Multi-language support (English and Hindi)
- Product management
- Inventory tracking
- Responsive design for mobile and web
- PIN-based security
- Material Design UI

## API Endpoints

- `POST /auth/login` - User login
- `POST /auth/register` - User registration
- `GET /user/profile` - Get current user profile
- `POST /products` - Add a product
- `GET /products` - List all products
- `PUT /products/{id}` - Update a product
- `DELETE /products/{id}` - Delete a product
- `GET /inventory` - Get inventory items

## Screenshots

[Add screenshots here]

## Future Enhancements

- Barcode scanning functionality
- Offline support
- Receipt printing
- Sales reports and analytics
- Customer loyalty program
