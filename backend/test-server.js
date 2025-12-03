const express = require('express');
const dotenv = require('dotenv');
const connectDatabase = require('./config/database');

// Load environment variables
dotenv.config();

// Connect to database
connectDatabase();

const app = express();

// Minimal middleware
app.use(express.json({ limit: '10mb' }));

// Health check only
app.get('/api/health', (req, res) => {
  res.json({ success: true, message: 'Server running' });
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, '127.0.0.1', () => {
  console.log(`🚀 Test server running on http://127.0.0.1:${PORT}`);
});
