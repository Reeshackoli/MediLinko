const mongoose = require('mongoose');
require('dotenv').config();

const HealthProfile = require('./models/HealthProfile');

const migrateEmergencyContacts = async () => {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Find all health profiles with flat emergency contact fields
    const profiles = await HealthProfile.find({
      $or: [
        { emergencyContactName: { $exists: true } },
        { emergencyPhone: { $exists: true } }
      ]
    });

    console.log(`📊 Found ${profiles.length} profiles with old emergency contact format`);

    let updated = 0;
    for (const profile of profiles) {
      // Check if already has nested structure
      if (profile.emergencyContact && profile.emergencyContact.name) {
        console.log(`⏭️  Skipping profile ${profile._id} - already migrated`);
        continue;
      }

      // Get flat fields
      const name = profile.get('emergencyContactName');
      const phone = profile.get('emergencyPhone');

      if (name || phone) {
        // Create nested structure
        profile.emergencyContact = {
          name: name || '',
          phone: phone || ''
        };

        // Remove flat fields
        profile.set('emergencyContactName', undefined, { strict: false });
        profile.set('emergencyPhone', undefined, { strict: false });
        profile.set('relationship', undefined, { strict: false });

        await profile.save();
        updated++;
        console.log(`✅ Updated profile ${profile._id}`);
      }
    }

    console.log(`\n🎉 Migration complete! Updated ${updated} profiles`);
    process.exit(0);
  } catch (error) {
    console.error('❌ Migration error:', error);
    process.exit(1);
  }
};

migrateEmergencyContacts();
