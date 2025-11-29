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

    res.status(200).json({
      success: true,
      count: pharmacies.length,
      data: pharmacies
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

    res.status(200).json({
      success: true,
      data: pharmacy
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};
