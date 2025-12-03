const mongoose = require('mongoose');
require('dotenv').config();

mongoose.connect(process.env.MONGODB_URI)
  .then(async () => {
    const DoctorProfile = require('./models/DoctorProfile');
    
    console.log('🔧 Fixing Dr. Prabhakar availability timings...\n');
    
    const result = await DoctorProfile.updateOne(
      { userId: new mongoose.Types.ObjectId('692fc4d195b62a0c0fe70b47') },
      { 
        $set: { 
          availableTimings: [
            { day: 'Monday', from: '09:00', to: '18:00' },
            { day: 'Tuesday', from: '09:00', to: '18:00' },
            { day: 'Wednesday', from: '09:00', to: '18:00' },
            { day: 'Thursday', from: '09:00', to: '18:00' },
            { day: 'Friday', from: '09:00', to: '18:00' },
            { day: 'Saturday', from: '09:00', to: '13:00' }
          ]
        }
      }
    );
    
    console.log('✅ Updated Dr. Prabhakar availability');
    console.log('   Modified:', result.modifiedCount);
    console.log('\n📅 Timings added:');
    console.log('   Monday-Friday: 9:00 AM - 6:00 PM');
    console.log('   Saturday: 9:00 AM - 1:00 PM');
    console.log('   Sunday: Closed\n');
    
    // Verify the update
    const profile = await DoctorProfile.findOne({ 
      userId: new mongoose.Types.ObjectId('692fc4d195b62a0c0fe70b47') 
    });
    
    console.log('✅ Verification:');
    console.log('   Total days configured:', profile.availableTimings.length);
    
    mongoose.connection.close();
    console.log('\n✅ Done! Try booking now.');
  })
  .catch(err => {
    console.error('❌ Error:', err.message);
    process.exit(1);
  });
