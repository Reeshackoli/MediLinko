const mongoose = require('mongoose');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log('✅ Connected to MongoDB'))
  .catch((err) => {
    console.error('❌ MongoDB connection error:', err);
    process.exit(1);
  });

const User = require('../models/User');
const PharmacistProfile = require('../models/PharmacistProfile');

async function testPharmacyAPI() {
  try {
    console.log('\n🔍 Testing Pharmacy API Data...\n');
    
    // Get all pharmacies
    const pharmacies = await User.find({ 
      role: 'pharmacist', 
      isProfileComplete: true 
    }).select('-password').lean();

    console.log(`📊 Total pharmacies: ${pharmacies.length}\n`);

    // Load pharmacist profiles
    const ids = pharmacies.map(p => p._id);
    const profiles = await PharmacistProfile.find({ userId: { $in: ids } }).lean();
    const profileMap = new Map(profiles.map(p => [p.userId.toString(), p]));

    // Merge data (similar to backend controller)
    const merged = pharmacies.map(p => {
      const prof = profileMap.get(p._id.toString());
      if (prof) {
        p.pharmacyName = p.pharmacyName || prof.storeName;
        p.storeName = p.storeName || prof.storeName;
        p.storeAddress = prof.storeAddress;
        p.operatingHours = prof.operatingHours;
        p.servicesOffered = prof.servicesOffered;
        p.deliveryRadius = prof.deliveryRadius;
      }
      return p;
    });

    // Show first 3 pharmacies with location data
    const withLocation = merged.filter(p => p.pharmacyLatitude && p.pharmacyLongitude);
    
    console.log(`✅ Pharmacies with location: ${withLocation.length}/${merged.length}\n`);
    
    if (withLocation.length > 0) {
      console.log('📍 Sample pharmacies with locations:\n');
      withLocation.slice(0, 3).forEach((p, i) => {
        console.log(`${i + 1}. ${p.storeName || p.email}`);
        console.log(`   Email: ${p.email}`);
        console.log(`   Location: ${p.pharmacyLatitude}, ${p.pharmacyLongitude}`);
        console.log(`   City: ${p.city || 'N/A'}`);
        if (p.storeAddress) {
          console.log(`   Address: ${p.storeAddress.fullAddress || `${p.storeAddress.street}, ${p.storeAddress.city}`}`);
        }
        if (p.operatingHours) {
          console.log(`   Hours: ${p.operatingHours.opening} - ${p.operatingHours.closing}`);
        }
        if (p.servicesOffered && p.servicesOffered.length > 0) {
          console.log(`   Services: ${p.servicesOffered.join(', ')}`);
        }
        console.log('');
      });
    } else {
      console.log('❌ No pharmacies have location data!');
      console.log('💡 Run: node backend/scripts/seed-pharmacy-locations.js\n');
    }

    // Check pharmacies without location
    const withoutLocation = merged.filter(p => !p.pharmacyLatitude || !p.pharmacyLongitude);
    if (withoutLocation.length > 0) {
      console.log(`⚠️  Pharmacies missing location data: ${withoutLocation.length}\n`);
      withoutLocation.forEach(p => {
        console.log(`   - ${p.email}: lat=${p.pharmacyLatitude}, lng=${p.pharmacyLongitude}`);
      });
    }

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    mongoose.connection.close();
    console.log('\n🔌 Database connection closed');
  }
}

testPharmacyAPI();
