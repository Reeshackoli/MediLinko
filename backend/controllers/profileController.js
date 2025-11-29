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
    
    console.log('📝 Profile Update Request:');
    console.log('User Role:', user.role);
    console.log('Profile Data:', JSON.stringify(profileData, null, 2));

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
    
    console.log('📥 Get Profile Response for user:', user.email);
    console.log('Profile data:', JSON.stringify(profile, null, 2));

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
