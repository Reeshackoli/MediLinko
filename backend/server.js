const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
// const morgan = require('morgan'); // Disabled to reduce memory usage
const dotenv = require('dotenv');
const connectDatabase = require('./config/database');
const { admin, messaging } = require('./config/firebase'); // Initialize Firebase
const { startScheduler } = require('./services/medicineReminderScheduler');

// Load environment variables
dotenv.config();

const app = express();

// Middleware
// Configure CORS for Flutter web app
app.use(cors({
  origin: '*', // Allow all origins in development
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Configure helmet with relaxed CSP for development
app.use(helmet({
  crossOriginResourcePolicy: { policy: "cross-origin" },
  contentSecurityPolicy: false // Disable CSP in development
}));

app.use(express.json()); // Parse JSON bodies
app.use(express.urlencoded({ extended: true })); // Parse URL-encoded bodies
// app.use(morgan('dev')); // Disabled to reduce memory usage

// Routes
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/profile', require('./routes/profileRoutes'));
app.use('/api/users', require('./routes/userRoutes'));
app.use('/api/medicines', require('./routes/medicineStockRoutes'));
app.use('/api/medicine', require('./routes/medicineRoutes'));
app.use('/api/medicine-reminders', require('./routes/medicineRemindersRoutes'));
app.use('/api/user-medicines', require('./routes/medicineRemindersRoutes'));
app.use('/api/appointments', require('./routes/appointmentRoutes'));
app.use('/api/notifications', require('./routes/notificationRoutes'));
app.use('/api/fcm', require('./routes/fcmRoutes'));
app.use('/api/ratings', require('./routes/ratingRoutes'));

// Health check route
app.get('/api/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'MediLinko API is running',
    timestamp: new Date().toISOString()
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found'
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    message: 'Internal server error',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

const PORT = process.env.PORT || 3000;
const HOST = '0.0.0.0'; // Use localhost specifically for Windows

// Start server after connecting to database
const startServer = async () => {
  try {
    // Connect to database first
    await connectDatabase();
    
    // Then start the server
    const server = app.listen(PORT, HOST, () => {
      console.log(`🚀 Server running on http://${HOST}:${PORT}`);
      console.log(`📍 Environment: ${process.env.NODE_ENV}`);
      console.log(`🌐 API available at http://localhost:${PORT}/api`);
      
      // Start medicine reminder scheduler AFTER database is connected
      startScheduler();
    });

    // Handle server errors
    server.on('error', (error) => {
      console.error('❌ Server error:', error);
      if (error.code === 'EADDRINUSE') {
        console.error(`Port ${PORT} is already in use`);
        process.exit(1);
      }
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
};

startServer();

module.exports = app;
