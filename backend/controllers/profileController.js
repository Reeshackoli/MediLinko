const User = require('../models/User');
const HealthProfile = require('../models/HealthProfile');
const DoctorProfile = require('../models/DoctorProfile');
const PharmacistProfile = require('../models/PharmacistProfile');

// @desc    Update user profile
// @route   PUT /api/profile
// @access  Private
exports.updateProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    let profile;
    const profileData = req.body;
    
    // Only log for doctor profiles with availability data
    if (user.role === 'doctor' && (profileData.availableTimings || profileData.availableDays)) {
      // Doctor profile update
      if (profileData.availableTimings) {
        // Available timings present
      } else if (profileData.availableDays || profileData.timeSlots) {
        // Old format detected
      }
    }

    // Handle profile based on user role
    if (user.role === 'user') {
      profile = await HealthProfile.findOneAndUpdate(
        { userId },
        profileData,
        { new: true, upsert: true, runValidators: true }
      );
    } else if (user.role === 'doctor') {
      profile = await DoctorProfile.findOneAndUpdate(
        { userId },
        profileData,
        { new: true, upsert: true, runValidators: true }
      );
      
      if (profileData.availableTimings) {
        // Timings saved
      }
      
      // Update user model with clinic location for map search
      if (profileData.clinicLatitude && profileData.clinicLongitude) {
        const lat = parseFloat(profileData.clinicLatitude);
        const lng = parseFloat(profileData.clinicLongitude);
        
        if (!isNaN(lat) && !isNaN(lng) && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
          await User.findByIdAndUpdate(userId, {
            clinicLatitude: lat,
            clinicLongitude: lng,
            'location.coordinates': [lng, lat] // GeoJSON format: [longitude, latitude]
          });
          // Location updated
        }
      }
    } else if (user.role === 'pharmacist') {
      profile = await PharmacistProfile.findOneAndUpdate(
        { userId },
        profileData,
        { new: true, upsert: true, runValidators: true }
      );
    }

    // Mark user profile as complete
    await User.findByIdAndUpdate(userId, { isProfileComplete: true });

    res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      data: profile
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Get user profile
// @route   GET /api/profile
// @access  Private
exports.getProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    let profile;

    // Get profile based on user role
    if (user.role === 'user') {
      profile = await HealthProfile.findOne({ userId });
    } else if (user.role === 'doctor') {
      profile = await DoctorProfile.findOne({ userId });
    } else if (user.role === 'pharmacist') {
      profile = await PharmacistProfile.findOne({ userId });
    }

    res.status(200).json({
      success: true,
      data: {
        user: {
          id: user._id,
          fullName: user.fullName,
          email: user.email,
          phone: user.phone,
          role: user.role,
          isProfileComplete: user.isProfileComplete
        },
        profile
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Update partial profile (wizard step)
// @route   PATCH /api/profile/wizard
// @access  Private
exports.updateWizardStep = async (req, res) => {
  try {
    const userId = req.user.id;
    const stepData = req.body;
    
    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    let profile;

    // Update profile based on user role
    if (user.role === 'user') {
      profile = await HealthProfile.findOneAndUpdate(
        { userId },
        { $set: stepData },
        { new: true, upsert: true, runValidators: false }
      );
    } else if (user.role === 'doctor') {
      profile = await DoctorProfile.findOneAndUpdate(
        { userId },
        { $set: stepData },
        { new: true, upsert: true, runValidators: false }
      );
      
      // Update user model with clinic location if provided
      if (stepData.clinicLatitude && stepData.clinicLongitude) {
        const lat = parseFloat(stepData.clinicLatitude);
        const lng = parseFloat(stepData.clinicLongitude);
        
        if (!isNaN(lat) && !isNaN(lng) && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
          await User.findByIdAndUpdate(userId, {
            clinicLatitude: lat,
            clinicLongitude: lng,
            'location.coordinates': [lng, lat]
          });
          console.log('✅ Updated doctor location in wizard step:', { lat, lng });
        }
      }
    } else if (user.role === 'pharmacist') {
      profile = await PharmacistProfile.findOneAndUpdate(
        { userId },
        { $set: stepData },
        { new: true, upsert: true, runValidators: false }
      );
    }

    res.status(200).json({
      success: true,
      message: 'Profile step updated successfully',
      data: profile
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};
