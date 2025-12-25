const mongoose = require('mongoose');

const connectDatabase = async () => {
  try {
    // Optimize mongoose settings for memory efficiency
    mongoose.set('strictQuery', false);
    // Enable command buffering so queries wait for connection
    mongoose.set('bufferCommands', true);
    
    const conn = await mongoose.connect(process.env.MONGODB_URI, {
      maxPoolSize: 10, // Limit connection pool size
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 45000,
    });

    console.log(`✅ MongoDB Connected: ${conn.connection.host}`);
    console.log(`📊 Database: ${conn.connection.name}`);
    
    return conn;
  } catch (error) {
    console.error('❌ MongoDB connection error:', error.message);
    process.exit(1);
  }
};

module.exports = connectDatabase;
