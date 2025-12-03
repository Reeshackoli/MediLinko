const mongoose = require('mongoose');
require('dotenv').config();

mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log(' Connected to MongoDB'))
  .catch((err) => {
    console.error(' MongoDB connection error:', err);
    process.exit(1);
  });

const User = require('../models/User');
const DoctorProfile = require('../models/DoctorProfile');

const belgaumDoctors = [
  {
    coordinates: { lat: 15.8497, lng: 74.4977 },
    specialization: 'Cardiologist',
    clinicName: 'Heart Care Belgaum',
    experience: 15,
    consultationFee: 600,
    availableTimings: [
      { day: 'Monday', from: '09:00', to: '17:00' },
      { day: 'Wednesday', from: '09:00', to: '17:00' },
      { day: 'Friday', from: '09:00', to: '17:00' },
    ]
  },
  {
    coordinates: { lat: 15.8551, lng: 74.5050 },
    specialization: 'Dentist',
    clinicName: 'Smile Dental Clinic',
    experience: 10,
    consultationFee: 400,
    availableTimings: [
      { day: 'Monday', from: '10:00', to: '18:00' },
      { day: 'Tuesday', from: '10:00', to: '18:00' },
      { day: 'Thursday', from: '10:00', to: '18:00' },
      { day: 'Saturday', from: '10:00', to: '14:00' },
    ]
  },
  {
    coordinates: { lat: 15.8395, lng: 74.4920 },
    specialization: 'Pediatrician',
    clinicName: 'Kids Care Hospital',
    experience: 12,
    consultationFee: 500,
    availableTimings: [
      { day: 'Monday', from: '08:00', to: '16:00' },
      { day: 'Tuesday', from: '08:00', to: '16:00' },
      { day: 'Wednesday', from: '08:00', to: '16:00' },
      { day: 'Thursday', from: '08:00', to: '16:00' },
      { day: 'Friday', from: '08:00', to: '16:00' },
    ]
  },
];

async function seedBelgaumDoctors() {
  try {
    console.log('\n Creating Belgaum area doctors (Pincode 590016)...\n');

    for (let i = 0; i < belgaumDoctors.length; i++) {
      const doctorData = belgaumDoctors[i];

      const user = await User.create({
        email: `doctor${i + 1}.belgaum@medilinko.com`,
        password: 'Doctor@123',
        fullName: `Dr. ${doctorData.specialization} Belgaum ${i + 1}`,
        phone: `987654321${i}`,
        role: 'doctor',
        isProfileComplete: true,
        specialization: doctorData.specialization,
        clinicName: doctorData.clinicName,
        clinicLatitude: doctorData.coordinates.lat,
        clinicLongitude: doctorData.coordinates.lng,
        location: {
          type: 'Point',
          coordinates: [doctorData.coordinates.lng, doctorData.coordinates.lat]
        },
        yearsOfExperience: doctorData.experience,
        consultationFee: doctorData.consultationFee,
      });

      await DoctorProfile.create({
        userId: user._id,
        specialization: doctorData.specialization,
        experience: doctorData.experience,
        consultationFee: doctorData.consultationFee,
        clinicName: doctorData.clinicName,
        clinicAddress: {
          street: 'Medical Road, Belgaum',
          city: 'Belgaum',
          pincode: '590016',
          fullAddress: 'Medical Road, Belgaum, Karnataka 590016'
        },
        availableTimings: doctorData.availableTimings,
        verificationStatus: 'approved',
      });

      console.log(`✅ Created: ${user.fullName} (${doctorData.specialization})`);
      console.log(`   Location: ${doctorData.coordinates.lat}, ${doctorData.coordinates.lng}`);
      console.log(`   Email: ${user.email} | Password: Doctor@123\n`);
    }

    console.log(`\n✨ Successfully seeded ${belgaumDoctors.length} doctors in Belgaum!\n`);
  } catch (error) {
    console.error('❌ Error seeding data:', error);
  } finally {
    mongoose.connection.close();
  }
}

seedBelgaumDoctors();
