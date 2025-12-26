const mongoose = require('mongoose');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log('✅ Connected to MongoDB'))
  .catch((err) => {
    console.error('❌ MongoDB connection error:', err);
    process.exit(1);
  });

const User = require('../models/User');

// Sample pharmacy locations in Belgaum/Belagavi (Karnataka)
const pharmacyLocations = [
  {
    storeName: 'Apollo Pharmacy',
    coordinates: { lat: 15.8497, lng: 74.4977 }, // Central Belgaum
    address: 'MG Road, Belgaum',
    city: 'Belgaum',
    pincode: '590001'
  },
  {
    storeName: 'MedPlus',
    coordinates: { lat: 15.8612, lng: 74.5081 }, // Tilakwadi
    address: 'Tilakwadi, Belgaum',
    city: 'Belgaum',
    pincode: '590006'
  },
  {
    storeName: 'Pharma Medical',
    coordinates: { lat: 15.8667, lng: 74.5167 }, // Angol
    address: 'Angol Road, Belgaum',
    city: 'Belgaum',
    pincode: '590001'
  },
  {
    storeName: '1mg Store',
    coordinates: { lat: 15.8333, lng: 74.4833 }, // Camp Area
    address: 'Camp Area, Belgaum',
    city: 'Belgaum',
    pincode: '590016'
  },
  {
    storeName: 'HealthBuddy Pharmacy',
    coordinates: { lat: 15.8550, lng: 74.5100 }, // Khanapur Road
    address: 'Khanapur Road, Belgaum',
    city: 'Belgaum',
    pincode: '590003'
  },
  {
    storeName: 'Wellness Forever',
    coordinates: { lat: 15.8444, lng: 74.5056 }, // Shahapur
    address: 'Shahapur, Belgaum',
    city: 'Belgaum',
    pincode: '590003'
  },
  {
    storeName: 'Netmeds Store',
    coordinates: { lat: 15.8700, lng: 74.5200 }, // Hindalga
    address: 'Hindalga Road, Belgaum',
    city: 'Belgaum',
    pincode: '591108'
  },
  {
    storeName: 'PharmEasy Outlet',
    coordinates: { lat: 15.8400, lng: 74.4900 }, // Maruti Galli
    address: 'Maruti Galli, Belgaum',
    city: 'Belgaum',
    pincode: '590001'
  },
  {
    storeName: 'City Medical',
    coordinates: { lat: 15.8600, lng: 74.5000 }, // Vadagaon
    address: 'Vadagaon, Belgaum',
    city: 'Belgaum',
    pincode: '590001'
  },
  {
    storeName: 'Care Pharmacy',
    coordinates: { lat: 15.8500, lng: 74.4950 }, // RPD Cross
    address: 'RPD Cross, Belgaum',
    city: 'Belgaum',
    pincode: '590001'
  },
  {
    storeName: 'LifeLine Medicals',
    coordinates: { lat: 15.8520, lng: 74.5020 }, // Khanjar Galli
    address: 'Khanjar Galli, Belgaum',
    city: 'Belgaum',
    pincode: '590045'
  },
];

async function seedPharmacyLocations() {
  try {
    console.log('\n🔍 Finding pharmacies without location data...\n');
    
    // Find all pharmacies without coordinates
    const pharmacies = await User.find({
      role: 'pharmacist',
      $or: [
        { pharmacyLatitude: { $exists: false } },
        { pharmacyLongitude: { $exists: false } },
        { pharmacyLatitude: null },
        { pharmacyLongitude: null },
        { pharmacyLatitude: 0 },
        { pharmacyLongitude: 0 }
      ]
    });

    if (pharmacies.length === 0) {
      console.log('✅ All pharmacies already have location data!');
      console.log('💡 Tip: Create new pharmacy accounts to seed with locations\n');
      return;
    }

    console.log(`📍 Found ${pharmacies.length} pharmacies without locations`);
    console.log('🌍 Adding Belgaum coordinates...\n');

    let updated = 0;
    for (let i = 0; i < pharmacies.length && i < pharmacyLocations.length; i++) {
      const pharmacy = pharmacies[i];
      const location = pharmacyLocations[i];

      // Update pharmacy with location data
      pharmacy.pharmacyLatitude = location.coordinates.lat;
      pharmacy.pharmacyLongitude = location.coordinates.lng;
      pharmacy.location = {
        type: 'Point',
        coordinates: [location.coordinates.lng, location.coordinates.lat]
      };
      pharmacy.city = location.city;

      await pharmacy.save();
      updated++;
      
      console.log(`✅ ${pharmacy.fullName || pharmacy.email}`);
      console.log(`   → ${location.storeName}`);
      console.log(`   → ${location.address}`);
      console.log(`   → Location: ${location.coordinates.lat}, ${location.coordinates.lng}\n`);
    }

    console.log(`\n🎉 Successfully seeded ${updated} pharmacies with location data!`);
    console.log('\n📊 Location Distribution:');
    console.log(`   • Belgaum/Belagavi: ${updated} pharmacies\n`);
    
  } catch (error) {
    console.error('❌ Error seeding data:', error);
  } finally {
    mongoose.connection.close();
    console.log('🔌 Database connection closed');
  }
}

// Run the seed script
seedPharmacyLocations();
