const mongoose = require('mongoose');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config();

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI)
  .then(() => {
    console.log('✅ Connected to MongoDB');
    deleteAllUsers();
  })
  .catch((error) => {
    console.error('❌ MongoDB connection error:', error.message);
    process.exit(1);
  });

async function deleteAllUsers() {
  try {
    const User = require('./models/User');
    const HealthProfile = require('./models/HealthProfile');
    const DoctorProfile = require('./models/DoctorProfile');
    const PharmacistProfile = require('./models/PharmacistProfile');
    
    // Delete all data
    const userResult = await User.deleteMany({});
    const healthResult = await HealthProfile.deleteMany({});
    const doctorResult = await DoctorProfile.deleteMany({});
    const pharmacistResult = await PharmacistProfile.deleteMany({});
    
    console.log(`🗑️  Deleted ${userResult.deletedCount} users`);
    console.log(`🗑️  Deleted ${healthResult.deletedCount} health profiles`);
    console.log(`🗑️  Deleted ${doctorResult.deletedCount} doctor profiles`);
    console.log(`🗑️  Deleted ${pharmacistResult.deletedCount} pharmacist profiles`);
    console.log('✅ All data has been removed from MongoDB');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error deleting data:', error.message);
    process.exit(1);
  }
}
