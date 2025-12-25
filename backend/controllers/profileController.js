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
    console.log('📝 Profile update request received');
    console.log('👤 User ID:', userId);
    console.log('📦 Request body:', JSON.stringify(req.body, null, 2));
    
    const user = await User.findById(userId);

    if (!user) {
      console.log('❌ User not found');
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    console.log('✅ User found:', user.email, '| Role:', user.role);

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
      console.log('💾 Updating HealthProfile...');
      
      // Get current profile BEFORE update
      const currentProfile = await HealthProfile.findOne({ userId });
      console.log('📋 BEFORE UPDATE:', JSON.stringify({
        emergencyContactName: currentProfile?.emergencyContactName,
        emergencyContactRelationship: currentProfile?.emergencyContactRelationship,
        city: currentProfile?.city
      }));
      
      profile = await HealthProfile.findOneAndUpdate(
        { userId },
        profileData,
        { new: true, upsert: true, runValidators: true }
      );
      
      console.log('📋 AFTER UPDATE:', JSON.stringify({
        emergencyContactName: profile?.emergencyContactName,
        emergencyContactRelationship: profile?.emergencyContactRelationship,
        city: profile?.city
      }));
      console.log('✅ HealthProfile updated:', profile ? 'Success' : 'Failed');
    } else if (user.role === 'doctor') {
      console.log('💾 Updating DoctorProfile...');
      profile = await DoctorProfile.findOneAndUpdate(
        { userId },
        profileData,
        { new: true, upsert: true, runValidators: true }
      );
      console.log('✅ DoctorProfile updated:', profile ? 'Success' : 'Failed');
      
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
      console.log('💾 Updating PharmacistProfile...');
      profile = await PharmacistProfile.findOneAndUpdate(
        { userId },
        profileData,
        { new: true, upsert: true, runValidators: true }
      );
      console.log('✅ PharmacistProfile updated:', profile ? 'Success' : 'Failed');
      // If pharmacist provided pharmacy coordinates, update user model location as well
      if (profileData.pharmacyLatitude && profileData.pharmacyLongitude) {
        const lat = parseFloat(profileData.pharmacyLatitude);
        const lng = parseFloat(profileData.pharmacyLongitude);

        if (!isNaN(lat) && !isNaN(lng) && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
          await User.findByIdAndUpdate(userId, {
            pharmacyLatitude: lat,
            pharmacyLongitude: lng,
            'location.coordinates': [lng, lat]
          });
        }
      }
    }

    // Mark user profile as complete
    await User.findByIdAndUpdate(userId, { isProfileComplete: true });

    console.log('✅ Profile update complete - sending response');
    res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      data: profile
    });
  } catch (error) {
    console.log('❌ Profile update error:', error.message);
    console.log('📋 Stack:', error.stack);
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
    console.log('📖 GET Profile request for user:', userId);
    
    const user = await User.findById(userId);

    if (!user) {
      console.log('❌ User not found');
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    console.log('✅ User found:', user.email, '| Role:', user.role);

    let profile;

    // Get profile based on user role
    if (user.role === 'user') {
      console.log('🔍 Fetching HealthProfile...');
      profile = await HealthProfile.findOne({ userId });
      console.log('📦 HealthProfile data:', JSON.stringify(profile, null, 2));
    } else if (user.role === 'doctor') {
      console.log('🔍 Fetching DoctorProfile...');
      profile = await DoctorProfile.findOne({ userId });
    } else if (user.role === 'pharmacist') {
      console.log('🔍 Fetching PharmacistProfile...');
      profile = await PharmacistProfile.findOne({ userId });
    }

    console.log('📤 Sending response with profile:', profile ? 'Found' : 'NULL');
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
      // If pharmacist provided pharmacy coordinates in wizard step, update User model location
      if (stepData.pharmacyLatitude && stepData.pharmacyLongitude) {
        const lat = parseFloat(stepData.pharmacyLatitude);
        const lng = parseFloat(stepData.pharmacyLongitude);

        if (!isNaN(lat) && !isNaN(lng) && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
          await User.findByIdAndUpdate(userId, {
            pharmacyLatitude: lat,
            pharmacyLongitude: lng,
            'location.coordinates': [lng, lat]
          });
          console.log('✅ Updated pharmacist location in wizard step:', { lat, lng });
        }
      }
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

// @desc    Get patient's health profile (for doctors)
// @route   GET /api/profile/patient/:patientId
// @access  Private (Doctor)
exports.getPatientHealthProfile = async (req, res) => {
  try {
    const { patientId } = req.params;
    const requesterId = req.user._id || req.user.id;

    console.log('📋 Fetching patient health profile:', { patientId, requesterId });

    // Verify requester is a doctor
    const requester = await User.findById(requesterId);
    if (!requester || requester.role !== 'doctor') {
      return res.status(403).json({
        success: false,
        message: 'Access denied. Doctor role required.',
      });
    }

    // Get patient user details
    const patient = await User.findById(patientId);
    if (!patient) {
      return res.status(404).json({
        success: false,
        message: 'Patient not found',
      });
    }

    // Get patient's health profile
    const healthProfile = await HealthProfile.findOne({ userId: patientId });

    res.json({
      success: true,
      patient: {
        id: patient._id,
        fullName: patient.fullName,
        email: patient.email,
        phone: patient.phone,
      },
      healthProfile: healthProfile || null,
    });
  } catch (error) {
    console.error('❌ Error fetching patient health profile:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message,
    });
  }
};
