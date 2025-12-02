const mongoose = require('mongoose');
require('dotenv').config();

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log('✅ Connected to MongoDB'))
  .catch((err) => {
    console.error('❌ MongoDB connection error:', err);
    process.exit(1);
  });

const User = require('../models/User');

// Sample doctor locations in Bangalore and Mumbai
const doctorLocations = [
  // Bangalore Doctors
  {
    specialization: 'Cardiologist',
    coordinates: { lat: 12.9716, lng: 77.5946 }, // Bangalore Central
    clinicName: 'Heart Care Clinic',
    experience: 15,
    consultationFee: 800
  },
  {
    specialization: 'Dentist',
    coordinates: { lat: 12.9352, lng: 77.6245 }, // Indiranagar
    clinicName: 'Smile Dental Care',
    experience: 8,
    consultationFee: 500
  },
  {
    specialization: 'Dermatologist',
    coordinates: { lat: 13.0358, lng: 77.5970 }, // Yelahanka
    clinicName: 'Skin & Glow Clinic',
    experience: 12,
    consultationFee: 700
  },
  {
    specialization: 'Pediatrician',
    coordinates: { lat: 12.9141, lng: 77.6411 }, // HSR Layout
    clinicName: 'Kids Care Hospital',
    experience: 10,
    consultationFee: 600
  },
  {
    specialization: 'Orthopedic',
    coordinates: { lat: 12.9279, lng: 77.6271 }, // Koramangala
    clinicName: 'Bone & Joint Center',
    experience: 18,
    consultationFee: 900
  },
  {
    specialization: 'ENT',
    coordinates: { lat: 12.9698, lng: 77.7499 }, // Whitefield
    clinicName: 'ENT Specialist Clinic',
    experience: 14,
    consultationFee: 650
  },
  {
    specialization: 'Gynecologist',
    coordinates: { lat: 12.8406, lng: 77.6595 }, // Electronic City
    clinicName: 'Women\'s Health Center',
    experience: 16,
    consultationFee: 750
  },
  {
    specialization: 'General Physician',
    coordinates: { lat: 12.9833, lng: 77.5952 }, // Malleshwaram
    clinicName: 'City Health Clinic',
    experience: 20,
    consultationFee: 400
  },
  
  // Mumbai Doctors
  {
    specialization: 'Cardiologist',
    coordinates: { lat: 19.0760, lng: 72.8777 }, // Mumbai Central
    clinicName: 'Mumbai Heart Institute',
    experience: 22,
    consultationFee: 1200
  },
  {
    specialization: 'Dentist',
    coordinates: { lat: 19.1136, lng: 72.8697 }, // Andheri
    clinicName: 'Perfect Smile Dental',
    experience: 9,
    consultationFee: 600
  },
  {
    specialization: 'Dermatologist',
    coordinates: { lat: 19.0596, lng: 72.8295 }, // Bandra
    clinicName: 'Glow Skin Clinic',
    experience: 13,
    consultationFee: 800
  },
  {
    specialization: 'Pediatrician',
    coordinates: { lat: 18.9220, lng: 72.8347 }, // Lower Parel
    clinicName: 'Little Angels Hospital',
    experience: 11,
    consultationFee: 700
  },
  {
    specialization: 'Orthopedic',
    coordinates: { lat: 19.1197, lng: 72.9073 }, // Powai
    clinicName: 'Advanced Orthopedics',
    experience: 19,
    consultationFee: 1000
  },
  {
    specialization: 'ENT',
    coordinates: { lat: 19.0330, lng: 72.8561 }, // Worli
    clinicName: 'ENT Care Center',
    experience: 15,
    consultationFee: 700
  },
  {
    specialization: 'Gynecologist',
    coordinates: { lat: 19.0176, lng: 72.8562 }, // Dadar
    clinicName: 'Maternal Care Hospital',
    experience: 17,
    consultationFee: 850
  },
  {
    specialization: 'General Physician',
    coordinates: { lat: 19.0728, lng: 72.8826 }, // Juhu
    clinicName: 'Family Health Clinic',
    experience: 21,
    consultationFee: 500
  },
];

async function seedDoctorLocations() {
  try {
    console.log('\n🔍 Finding doctors without location data...\n');
    
    // Find all doctors without coordinates
    const doctors = await User.find({
      role: 'doctor',
      $or: [
        { clinicLatitude: { $exists: false } },
        { clinicLongitude: { $exists: false } },
        { clinicLatitude: null },
        { clinicLongitude: null }
      ]
    }).limit(16); // Match the number of sample locations

    if (doctors.length === 0) {
      console.log('✅ All doctors already have location data!');
      console.log('💡 Tip: Create new doctor accounts to seed with locations\n');
      return;
    }

    console.log(`📍 Found ${doctors.length} doctors without locations`);
    console.log('🌍 Adding sample coordinates...\n');

    let updated = 0;
    for (let i = 0; i < doctors.length && i < doctorLocations.length; i++) {
      const doctor = doctors[i];
      const location = doctorLocations[i];

      // Update doctor with location data
      doctor.specialization = location.specialization;
      doctor.clinicLatitude = location.coordinates.lat;
      doctor.clinicLongitude = location.coordinates.lng;
      doctor.location = {
        type: 'Point',
        coordinates: [location.coordinates.lng, location.coordinates.lat]
      };
      doctor.clinicName = location.clinicName;
      doctor.yearsOfExperience = location.experience;
      doctor.consultationFee = location.consultationFee;

      await doctor.save();
      updated++;
      
      console.log(`✅ ${doctor.fullName || doctor.email}`);
      console.log(`   → ${location.specialization} at ${location.clinicName}`);
      console.log(`   → Location: ${location.coordinates.lat}, ${location.coordinates.lng}\n`);
    }

    console.log(`\n🎉 Successfully seeded ${updated} doctors with location data!`);
    console.log('\n📊 Location Distribution:');
    console.log(`   • Bangalore: 8 doctors`);
    console.log(`   • Mumbai: 8 doctors\n`);
    
  } catch (error) {
    console.error('❌ Error seeding data:', error);
  } finally {
    mongoose.connection.close();
    console.log('🔌 Database connection closed');
  }
}

// Run the seed script
seedDoctorLocations();
