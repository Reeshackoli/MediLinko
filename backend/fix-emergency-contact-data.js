const mongoose = require('mongoose');
const HealthProfile = require('./models/HealthProfile');
require('dotenv').config();

const fixEmergencyContactData = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('📦 Connected to MongoDB');

    // Find all health profiles with old nested emergencyContact structure
    const profiles = await HealthProfile.find({}).lean();
    
    console.log(`Found ${profiles.length} total profiles\n`);
    
    let fixed = 0;
    for (const profile of profiles) {
      const updates = {};
      const unset = {};
      
      // Check if has old emergencyContact object
      if (profile.emergencyContact && typeof profile.emergencyContact === 'object') {
        console.log(`Fixing profile ${profile._id}:`);
        console.log('  Old emergencyContact:', profile.emergencyContact);
        
        // Extract data from nested object
        if (profile.emergencyContact.name) {
          updates.emergencyContactName = profile.emergencyContact.name;
        }
        if (profile.emergencyContact.relationship) {
          updates.emergencyContactRelationship = profile.emergencyContact.relationship;
        }
        if (profile.emergencyContact.phone) {
          updates.emergencyContactPhone = profile.emergencyContact.phone;
        }
        
        // Remove old nested field
        unset.emergencyContact = "";
        
        // Apply updates
        await HealthProfile.findByIdAndUpdate(
          profile._id,
          {
            $set: updates,
            $unset: unset
          }
        );
        
        fixed++;
        console.log(`  ✅ Updated to flat fields:`, updates);
      }
    }

    console.log(`\n🎉 Migration complete! Fixed ${fixed} profiles`);
    await mongoose.connection.close();
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
};

fixEmergencyContactData();
