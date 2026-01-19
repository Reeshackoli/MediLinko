const axios = require('axios');

// Configure emergencyMed service URL
const EMERGENCY_MED_URL = process.env.EMERGENCY_MED_URL || 'http://localhost:5000';

/**
 * Sync user emergency data to emergencyMed service
 * Called when user updates their health profile
 */
exports.syncEmergencyData = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { healthProfile } = req.body;

    if (!healthProfile) {
      return res.status(400).json({
        success: false,
        message: 'Health profile data is required',
      });
    }

    // Prepare emergency data for sync
    const emergencyData = {
      medilinkoUserId: userId,
      fullName: healthProfile.name || req.user.fullName,
      email: req.user.email,
      phone: req.user.phone,
      role: req.user.role,
      bloodGroup: healthProfile.bloodGroup,
      allergies: healthProfile.allergies || [],
      conditions: healthProfile.conditions || [],
      currentMedicines: healthProfile.currentMedicines || [],
      emergencyContactName: healthProfile.emergencyContactName,
      emergencyContactRelationship: healthProfile.emergencyContactRelationship,
      emergencyContactPhone: healthProfile.emergencyContactPhone,
      emergencyContactName2: healthProfile.emergencyContactName2,
      emergencyContactRelationship2: healthProfile.emergencyContactRelationship2,
      emergencyContactPhone2: healthProfile.emergencyContactPhone2,
    };

    // Send to emergencyMed service
    const response = await axios.post(
      `${EMERGENCY_MED_URL}/api/users/sync-from-medilinko`,
      emergencyData,
      {
        timeout: 10000,
        headers: {
          'Content-Type': 'application/json',
        },
      }
    );

    if (response.status === 200 || response.status === 201) {
      console.log(`✅ Emergency data synced for user ${userId}`);
      return res.status(200).json({
        success: true,
        message: 'Emergency data synced successfully',
        emergencyUserId: response.data.userId,
      });
    } else {
      throw new Error(`Unexpected response: ${response.status}`);
    }
  } catch (error) {
    console.error('❌ Error syncing emergency data:', error.message);
    
    // Don't fail the main request if sync fails
    return res.status(200).json({
      success: true,
      message: 'Profile updated (emergency sync failed)',
      syncError: error.message,
    });
  }
};

/**
 * Register new user in emergencyMed service
 * Called during user registration
 */
exports.registerInEmergencyMed = async (userData) => {
  try {
    const emergencyData = {
      medilinkoUserId: userData.userId,
      fullName: userData.fullName,
      email: userData.email,
      phone: userData.phone,
      role: userData.role,
    };

    const response = await axios.post(
      `${EMERGENCY_MED_URL}/api/users/register-from-medilinko`,
      emergencyData,
      {
        timeout: 10000,
        headers: {
          'Content-Type': 'application/json',
        },
      }
    );

    if (response.status === 200 || response.status === 201) {
      console.log(`✅ User registered in emergencyMed: ${response.data.userId}`);
      return response.data.userId;
    }

    return null;
  } catch (error) {
    console.error('⚠️ Failed to register in emergencyMed:', error.message);
    // Don't fail registration if emergencyMed is down
    return null;
  }
};

/**
 * Get QR URL for user emergency profile
 */
exports.getQRUrl = async (req, res) => {
  try {
    const userId = req.user.userId;

    // Check if emergencyMed service is available
    const response = await axios.get(
      `${EMERGENCY_MED_URL}/api/users/${userId}/qr-url`,
      { timeout: 5000 }
    );

    if (response.status === 200) {
      return res.status(200).json({
        success: true,
        qrUrl: response.data.qrUrl,
      });
    }

    throw new Error('Failed to fetch QR URL');
  } catch (error) {
    console.error('❌ Error fetching QR URL:', error.message);
    return res.status(503).json({
      success: false,
      message: 'Emergency service unavailable',
      error: error.message,
    });
  }
};

/**
 * Check if emergencyMed service is healthy
 */
exports.checkEmergencyService = async (req, res) => {
  try {
    const response = await axios.get(`${EMERGENCY_MED_URL}/health`, {
      timeout: 3000,
    });

    return res.status(200).json({
      success: true,
      available: response.status === 200,
      url: EMERGENCY_MED_URL,
    });
  } catch (error) {
    return res.status(200).json({
      success: true,
      available: false,
      url: EMERGENCY_MED_URL,
      error: error.message,
    });
  }
};
