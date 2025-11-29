# MediLinko Backend API

Node.js/Express backend with MongoDB for MediLinko healthcare application.

## 🚀 Quick Start

### Install Dependencies
```bash
cd backend
npm install
```

### Start Development Server
```bash
npm run dev
```

### Start Production Server
```bash
npm start
```

Server runs on: `http://localhost:3000`

## 📡 API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user (Protected)

### Profile Management
- `GET /api/profile` - Get user profile (Protected)
- `PUT /api/profile` - Update complete profile (Protected)
- `PATCH /api/profile/wizard` - Update wizard step (Protected)

### Users/Discovery
- `GET /api/users/doctors` - Get all doctors
- `GET /api/users/doctors/:id` - Get doctor by ID
- `GET /api/users/pharmacies` - Get all pharmacies
- `GET /api/users/pharmacies/:id` - Get pharmacy by ID

### Health Check
- `GET /api/health` - Server health check

## 🔑 Request Examples

### Register
```bash
POST http://localhost:3000/api/auth/register
Content-Type: application/json

{
  "fullName": "John Doe",
  "email": "john@example.com",
  "phone": "9876543210",
  "password": "password123",
  "role": "user"
}
```

### Login
```bash
POST http://localhost:3000/api/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "password123"
}
```

### Update Profile
```bash
PUT http://localhost:3000/api/profile
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: application/json

{
  "ageOrDob": "25",
  "gender": "Male",
  "city": "Mumbai",
  "bloodGroup": "O+",
  "isProfileComplete": true
}
```

### Get Doctors
```bash
GET http://localhost:3000/api/users/doctors?specialization=Cardiologist&city=Mumbai
```

## 🔐 Authentication

The API uses JWT (JSON Web Tokens) for authentication.

1. Register or login to get a token
2. Include token in Authorization header for protected routes:
   ```
   Authorization: Bearer YOUR_JWT_TOKEN
   ```

## 🗄️ Database Schema

### User Model
- Common fields: fullName, email, phone, password, role
- User-specific: ageOrDob, gender, city, bloodGroup, allergies, etc.
- Doctor-specific: experience, specialization, clinicName, etc.
- Pharmacist-specific: pharmacyName, openingTime, servicesOffered, etc.

## 🌐 CORS

CORS is enabled for all origins in development. Update in production for security.

## 📝 Environment Variables

Create `.env` file in backend directory:
```
MONGODB_URI=your_mongodb_connection_string
JWT_SECRET=your_jwt_secret
JWT_EXPIRE=7d
PORT=3000
NODE_ENV=development
```

## 🧪 Testing with Postman/Thunder Client

Import this collection or test manually with the endpoints above.

## 🔧 Technologies

- **Express.js** - Web framework
- **MongoDB** - Database
- **Mongoose** - ODM
- **JWT** - Authentication
- **bcryptjs** - Password hashing
- **Helmet** - Security headers
- **Morgan** - Request logging
- **CORS** - Cross-origin resource sharing

## 📦 Project Structure

```
backend/
├── config/
│   └── database.js
├── controllers/
│   ├── authController.js
│   ├── profileController.js
│   └── userController.js
├── middleware/
│   └── auth.js
├── models/
│   └── User.js
├── routes/
│   ├── authRoutes.js
│   ├── profileRoutes.js
│   └── userRoutes.js
├── .env
├── .gitignore
├── package.json
├── README.md
└── server.js
```

## 🚨 Error Handling

All endpoints return consistent JSON responses:

**Success:**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

**Error:**
```json
{
  "success": false,
  "message": "Error description"
}
```

## 📱 Flutter Integration

Base URL: `http://localhost:3000/api`

For production, deploy backend and update Flutter app's base URL.

## 🔒 Security Notes

- Passwords are hashed with bcrypt
- JWT tokens expire after 7 days (configurable)
- Helmet adds security headers
- Input validation on all routes
- MongoDB injection protection via Mongoose

## 📄 License

MIT
