const mongoose = require('mongoose');
const User = require('./models/User');
const HealthProfile = require('./models/HealthProfile');
const DoctorProfile = require('./models/DoctorProfile');
const PharmacistProfile = require('./models/PharmacistProfile');
require('dotenv').config();

const deleteTestUser = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('📦 Connected to MongoDB');

    // Find user with fullName "test kumar" (case insensitive)
    const testUser = await User.findOne({ 
      fullName: { $regex: /^test kumar$/i } 
    });

    if (!testUser) {
      console.log('❌ No user found with name "test"');
      await mongoose.connection.close();
      return;
    }

    console.log(`Found user: ${testUser.fullName} (${testUser.email})`);
    
    // Delete associated profiles
    if (testUser.role === 'user') {
      await HealthProfile.deleteOne({ userId: testUser._id });
      console.log('✅ Deleted health profile');
    } else if (testUser.role === 'doctor') {
      await DoctorProfile.deleteOne({ userId: testUser._id });
      console.log('✅ Deleted doctor profile');
    } else if (testUser.role === 'pharmacist') {
      await PharmacistProfile.deleteOne({ userId: testUser._id });
      console.log('✅ Deleted pharmacist profile');
    }

    // Delete the user
    await User.deleteOne({ _id: testUser._id });
    console.log('✅ Deleted user "test"');

    await mongoose.connection.close();
    console.log('🎉 Test user deleted successfully');
  } catch (error) {
    console.error('❌ Error:', error);
    await mongoose.connection.close();
  }
};

deleteTestUser();
