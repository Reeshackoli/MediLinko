const mongoose = require('mongoose');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

const User = require('../models/User');
const UserMedicine = require('../models/UserMedicine');
const MedicineDose = require('../models/MedicineDose');

const addTestMedicines = async () => {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });

    console.log('✅ Connected to MongoDB');

    // Find user sushil@gmail.com
    const user = await User.findOne({ email: 'sushil@gmail.com' });
    if (!user) {
      console.log('❌ User not found');
      return;
    }

    console.log(`✅ Found user: ${user.fullName} (${user.email})`);

    // Clear existing medicines for this user
    await UserMedicine.deleteMany({ userId: user._id });
    console.log('🗑️  Cleared existing medicines');

    // Create sample medicines
    const medicines = [
      {
        userId: user._id,
        medicineName: 'Aspirin',
        dosage: '100mg',
        startDate: new Date(),
        endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
        notes: 'Take after meals',
        isActive: true,
      },
      {
        userId: user._id,
        medicineName: 'Vitamin D',
        dosage: '1000 IU',
        startDate: new Date(),
        endDate: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000), // 90 days
        notes: 'Take with breakfast',
        isActive: true,
      },
      {
        userId: user._id,
        medicineName: 'Metformin',
        dosage: '500mg',
        startDate: new Date(),
        endDate: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000), // 60 days
        notes: 'For diabetes',
        isActive: true,
      },
    ];

    const createdMedicines = await UserMedicine.insertMany(medicines);
    console.log(`✅ Created ${createdMedicines.length} medicines`);

    // Create doses for each medicine
    const doses = [
      // Aspirin - once daily
      {
        userMedicineId: createdMedicines[0]._id,
        time: '09:00',
        frequency: 'daily',
      },
      // Vitamin D - once daily
      {
        userMedicineId: createdMedicines[1]._id,
        time: '08:00',
        frequency: 'daily',
      },
      // Metformin - twice daily
      {
        userMedicineId: createdMedicines[2]._id,
        time: '08:30',
        frequency: 'daily',
      },
      {
        userMedicineId: createdMedicines[2]._id,
        time: '20:00',
        frequency: 'daily',
      },
    ];

    const createdDoses = await MedicineDose.insertMany(doses);
    console.log(`✅ Created ${createdDoses.length} doses`);

    console.log('\n📋 Summary:');
    for (const medicine of createdMedicines) {
      const medicineDoses = createdDoses.filter(
        d => d.userMedicineId.toString() === medicine._id.toString()
      );
      console.log(`  ${medicine.medicineName} (${medicine.dosage})`);
      medicineDoses.forEach(dose => {
        console.log(`    - ${dose.time} (${dose.frequency})`);
      });
    }

    console.log('\n✅ Test medicines added successfully!');
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('👋 Disconnected from MongoDB');
  }
};

addTestMedicines();
