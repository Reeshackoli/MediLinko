const User = require('../models/User');

// @desc    Get all doctors
// @route   GET /api/users/doctors
// @access  Public
exports.getDoctors = async (req, res) => {
  try {
    const { specialization, city } = req.query;
    
    let query = { role: 'doctor', isProfileComplete: true };
    
    if (specialization) {
      query.specialization = specialization;
    }
    
    if (city) {
      query.city = new RegExp(city, 'i');
    }

    const doctors = await User.find(query).select('-password');

    res.status(200).json({
      success: true,
      count: doctors.length,
      data: doctors
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Get all pharmacies
// @route   GET /api/users/pharmacies
// @access  Public
exports.getPharmacies = async (req, res) => {
  try {
    const { city } = req.query;
    
    let query = { role: 'pharmacist', isProfileComplete: true };
    
    if (city) {
      query.city = new RegExp(city, 'i');
    }

    const pharmacies = await User.find(query).select('-password');

    // Load pharmacist profiles in bulk and merge storeName into user result when available
    const ids = pharmacies.map(p => p._id);
    const PharmacistProfile = require('../models/PharmacistProfile');
    const profiles = await PharmacistProfile.find({ userId: { $in: ids } }).lean();
    const profileMap = new Map(profiles.map(p => [p.userId.toString(), p]));

    const merged = pharmacies.map(p => {
      const obj = p.toObject();
      const prof = profileMap.get(p._id.toString());
      if (prof && prof.storeName) {
        obj.pharmacyName = obj.pharmacyName || prof.storeName;
        obj.storeName = obj.storeName || prof.storeName;
      }
      return obj;
    });

    res.status(200).json({
      success: true,
      count: merged.length,
      data: merged
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Get doctor by ID
// @route   GET /api/users/doctors/:id
// @access  Public
exports.getDoctorById = async (req, res) => {
  try {
    const doctor = await User.findOne({
      _id: req.params.id,
      role: 'doctor'
    }).select('-password');

    if (!doctor) {
      return res.status(404).json({
        success: false,
        message: 'Doctor not found'
      });
    }

    res.status(200).json({
      success: true,
      data: doctor
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Get pharmacy by ID
// @route   GET /api/users/pharmacies/:id
// @access  Public
exports.getPharmacyById = async (req, res) => {
  try {
    const pharmacy = await User.findOne({
      _id: req.params.id,
      role: 'pharmacist'
    }).select('-password');

    if (!pharmacy) {
      return res.status(404).json({
        success: false,
        message: 'Pharmacy not found'
      });
    }

    // Attempt to merge storeName from PharmacistProfile
    const PharmacistProfile = require('../models/PharmacistProfile');
    const prof = await PharmacistProfile.findOne({ userId: pharmacy._id }).lean();
    const result = pharmacy.toObject();
    if (prof && prof.storeName) {
      result.pharmacyName = result.pharmacyName || prof.storeName;
      result.storeName = result.storeName || prof.storeName;
    }

    res.status(200).json({
      success: true,
      data: result
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Get nearby doctors based on location
// @route   GET /api/users/doctors/nearby
// @access  Public
exports.getNearbyDoctors = async (req, res) => {
  try {
    const { lat, lng, radius = 5000, specialization } = req.query;

    // Validate coordinates
    if (!lat || !lng) {
      return res.status(400).json({
        success: false,
        message: 'Please provide latitude and longitude'
      });
    }

    const latitude = parseFloat(lat);
    const longitude = parseFloat(lng);
    const radiusInMeters = parseFloat(radius);

    if (isNaN(latitude) || isNaN(longitude) || isNaN(radiusInMeters)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid coordinate values'
      });
    }

    // Build query
    let query = {
      role: 'doctor',
      isProfileComplete: true,
      clinicLatitude: { $exists: true, $ne: null },
      clinicLongitude: { $exists: true, $ne: null },
      location: {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [longitude, latitude]
          },
          $maxDistance: radiusInMeters
        }
      }
    };

    // Add specialization filter if provided
    if (specialization) {
      query.specialization = new RegExp(specialization, 'i');
    }

    const doctors = await User.find(query).select('-password');

    // Calculate distance for each doctor
    const doctorsWithDistance = doctors.map(doctor => {
      const docObj = doctor.toObject();
      
      // Calculate distance using Haversine formula
      const R = 6371e3; // Earth radius in meters
      const φ1 = latitude * Math.PI / 180;
      const φ2 = docObj.clinicLatitude * Math.PI / 180;
      const Δφ = (docObj.clinicLatitude - latitude) * Math.PI / 180;
      const Δλ = (docObj.clinicLongitude - longitude) * Math.PI / 180;

      const a = Math.sin(Δφ/2) * Math.sin(Δφ/2) +
                Math.cos(φ1) * Math.cos(φ2) *
                Math.sin(Δλ/2) * Math.sin(Δλ/2);
      const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
      const distance = R * c;

      return {
        ...docObj,
        distance: Math.round(distance) // distance in meters
      };
    });

    res.status(200).json({
      success: true,
      count: doctorsWithDistance.length,
      data: doctorsWithDistance
    });
  } catch (error) {
    console.error('Error in getNearbyDoctors:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Get nearby pharmacies based on location
// @route   GET /api/users/pharmacies/nearby
// @access  Public
exports.getNearbyPharmacies = async (req, res) => {
  try {
    const { lat, lng, radius = 5000 } = req.query;

    // Validate coordinates
    if (!lat || !lng) {
      return res.status(400).json({
        success: false,
        message: 'Please provide latitude and longitude'
      });
    }

    const latitude = parseFloat(lat);
    const longitude = parseFloat(lng);
    const radiusInMeters = parseFloat(radius);

    if (isNaN(latitude) || isNaN(longitude) || isNaN(radiusInMeters)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid coordinate values'
      });
    }

    // Build query
    let query = {
      role: 'pharmacist',
      isProfileComplete: true,
      pharmacyLatitude: { $exists: true, $ne: null },
      pharmacyLongitude: { $exists: true, $ne: null },
      location: {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [longitude, latitude]
          },
          $maxDistance: radiusInMeters
        }
      }
    };

    const pharmacies = await User.find(query).select('-password');

    // Load pharmacist profiles in bulk and merge storeName into user result when available
    const ids = pharmacies.map(p => p._id);
    const PharmacistProfile = require('../models/PharmacistProfile');
    const profiles = await PharmacistProfile.find({ userId: { $in: ids } }).lean();
    const profileMap = new Map(profiles.map(p => [p.userId.toString(), p]));

    const merged = pharmacies.map(p => {
      const obj = p.toObject();
      const prof = profileMap.get(p._id.toString());
      if (prof && prof.storeName) {
        obj.pharmacyName = obj.pharmacyName || prof.storeName;
        obj.storeName = obj.storeName || prof.storeName;
      }
      return obj;
    });

    // Calculate distance for each pharmacy
    const pharmaciesWithDistance = merged.map(pharmacy => {
      const pharmObj = pharmacy;
      
      // Calculate distance using Haversine formula
      const R = 6371e3; // Earth radius in meters
      const φ1 = latitude * Math.PI / 180;
      const φ2 = pharmObj.pharmacyLatitude * Math.PI / 180;
      const Δφ = (pharmObj.pharmacyLatitude - latitude) * Math.PI / 180;
      const Δλ = (pharmObj.pharmacyLongitude - longitude) * Math.PI / 180;

      const a = Math.sin(Δφ/2) * Math.sin(Δφ/2) +
                Math.cos(φ1) * Math.cos(φ2) *
                Math.sin(Δλ/2) * Math.sin(Δλ/2);
      const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
      const distance = R * c;

      return {
        ...pharmObj,
        distance: Math.round(distance) // distance in meters
      };
    });

    res.status(200).json({
      success: true,
      count: pharmaciesWithDistance.length,
      data: pharmaciesWithDistance
    });
  } catch (error) {
    console.error('Error in getNearbyPharmacies:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};