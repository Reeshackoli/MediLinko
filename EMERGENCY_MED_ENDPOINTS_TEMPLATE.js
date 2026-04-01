/**
 * EmergencyMed Backend - MediLinko Integration Endpoints
 * 
 * Add these routes to your emergencyMed Express server
 * to enable integration with MediLinko
 */

const express = require('express');
const router = express.Router();

/**
 * @route   POST /api/users/sync-from-medilinko
 * @desc    Receive user data from MediLinko and create/update emergency profile
 * @access  Public (add API key auth in production)
 */
router.post('/sync-from-medilinko', async (req, res) => {
  try {
    const {
      medilinkoUserId,
      fullName,
      email,
      phone,
      role,
      bloodGroup,
      allergies,
      conditions,
      currentMedicines,
      emergencyContactName,
      emergencyContactRelationship,
      emergencyContactPhone,
      emergencyContactName2,
      emergencyContactRelationship2,
      emergencyContactPhone2,
    } = req.body;

    console.log('📥 Received sync request from MediLinko:', medilinkoUserId);

    // TODO: Replace with your database logic
    // Example with MongoDB:
    
    /*
    const User = require('../models/User'); // Your User model
    
    // Find existing user by MediLinko ID or create new one
    let user = await User.findOne({ medilinkoUserId });
    
    if (user) {
      // Update existing user
      user.fullName = fullName;
      user.email = email;
      user.phone = phone;
      user.bloodGroup = bloodGroup;
      user.allergies = allergies;
      user.conditions = conditions;
      user.currentMedicines = currentMedicines;
      user.emergencyContactName = emergencyContactName;
      user.emergencyContactRelationship = emergencyContactRelationship;
      user.emergencyContactPhone = emergencyContactPhone;
      user.emergencyContactName2 = emergencyContactName2;
      user.emergencyContactRelationship2 = emergencyContactRelationship2;
      user.emergencyContactPhone2 = emergencyContactPhone2;
      user.updatedAt = new Date();
      
      await user.save();
      console.log('✅ User updated:', user.userId);
    } else {
      // Create new user
      user = new User({
        medilinkoUserId,
        userId: `ML-${role.toUpperCase()}-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
        fullName,
        email,
        phone,
        role,
        bloodGroup,
        allergies,
        conditions,
        currentMedicines,
        emergencyContactName,
        emergencyContactRelationship,
        emergencyContactPhone,
        emergencyContactName2,
        emergencyContactRelationship2,
        emergencyContactPhone2,
      });
      
      await user.save();
      console.log('✅ User created:', user.userId);
    }
    
    return res.status(200).json({
      success: true,
      userId: user.userId,
      message: 'User synced successfully',
    });
    */

    // TEMPORARY: Mock response for testing
    const mockUserId = `ML-${role.toUpperCase()}-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    
    console.log('✅ Mock sync successful (replace with real DB logic)');
    
    return res.status(200).json({
      success: true,
      userId: mockUserId,
      message: 'User synced successfully (MOCK - implement DB logic)',
    });

  } catch (error) {
    console.error('❌ Error syncing user:', error);
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

/**
 * @route   GET /api/users/:userId/qr-url
 * @desc    Get QR URL for user emergency profile
 * @access  Public
 */
router.get('/:userId/qr-url', async (req, res) => {
  try {
    const { userId } = req.params;

    // TODO: Verify user exists in your database
    /*
    const User = require('../models/User');
    const user = await User.findOne({ userId });
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }
    */

    // Generate QR URL (update domain in production)
    const baseUrl = process.env.PUBLIC_URL || 'http://localhost:3000';
    const qrUrl = `${baseUrl}/profile/${userId}`;

    console.log('✅ QR URL generated:', qrUrl);

    return res.status(200).json({
      qrUrl,
    });

  } catch (error) {
    console.error('❌ Error generating QR URL:', error);
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

/**
 * @route   GET /api/users/:userId
 * @desc    Get user profile data (for verification)
 * @access  Public
 */
router.get('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    // TODO: Fetch user from database
    /*
    const User = require('../models/User');
    const user = await User.findOne({ userId });
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }
    
    return res.status(200).json({
      success: true,
      user: {
        userId: user.userId,
        fullName: user.fullName,
        bloodGroup: user.bloodGroup,
        allergies: user.allergies,
        emergencyContactName: user.emergencyContactName,
        emergencyContactPhone: user.emergencyContactPhone,
      }
    });
    */

    // TEMPORARY: Mock response
    return res.status(200).json({
      success: true,
      user: {
        userId,
        fullName: 'Mock User',
        bloodGroup: 'O+',
        allergies: ['None'],
      }
    });

  } catch (error) {
    console.error('❌ Error fetching user:', error);
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

module.exports = router;

// ========================================
// Add to your emergencyMed server.js:
// ========================================
/*

const medilinkoRoutes = require('./routes/medilinkoRoutes'); // This file

// Add this route
app.use('/api/users', medilinkoRoutes);

// Add health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

*/
