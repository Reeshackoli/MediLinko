const axios = require('axios');
const QRCode = require('qrcode');

// Configure emergencyMed service URLs
const EMERGENCY_MED_URL = process.env.EMERGENCY_MED_URL || 'http://localhost:5000';
const EMERGENCY_WEB_URL = process.env.EMERGENCY_WEB_URL || 'http://localhost:3001';

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
 * Helper function to get emergency user ID from emergencyMed backend
 */
const getEmergencyUserId = async (medilinkoUserId) => {
  try {
    const response = await axios.get(
      `${EMERGENCY_MED_URL}/api/users/medilinko/${medilinkoUserId}`,
      { timeout: 5000 }
    );
    
    if (response.status === 200 && response.data.user) {
      return response.data.user.userId; // Emergency user ID (e.g., ML-USER-...)
    }
    return null;
  } catch (error) {
    console.error('⚠️ Error fetching emergency user ID:', error.message);
    return null;
  }
};

/**
 * Get QR URL for user emergency profile
 */
exports.getQRUrl = async (req, res) => {
  try {
    const userId = req.user.userId;

    // Get emergency user ID from emergencyMed backend
    const emergencyUserId = await getEmergencyUserId(userId);
    
    if (!emergencyUserId) {
      return res.status(404).json({
        success: false,
        message: 'Emergency profile not found. Please sync your health profile first.',
      });
    }

    // Generate web profile URL
    const qrUrl = `${EMERGENCY_WEB_URL}/profile/${emergencyUserId}`;

    return res.status(200).json({
      success: true,
      qrUrl: qrUrl,
      emergencyUserId: emergencyUserId,
    });
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

/**
 * Generate QR code image for emergency profile
 * Returns QR code as image (PNG)
 */
exports.generateQRCode = async (req, res) => {
  try {
    const userId = req.user.userId;
    
    // Get emergency user ID from emergencyMed backend
    const emergencyUserId = await getEmergencyUserId(userId);
    
    if (!emergencyUserId) {
      return res.status(404).json({
        success: false,
        message: 'Emergency profile not found. Please sync your health profile first.',
      });
    }
    
    // Generate web profile URL
    const emergencyUrl = `${EMERGENCY_WEB_URL}/profile/${emergencyUserId}`;
    
    // Generate QR code as PNG buffer
    const qrCodeBuffer = await QRCode.toBuffer(emergencyUrl, {
      errorCorrectionLevel: 'H',
      type: 'png',
      width: 300,
      margin: 2,
      color: {
        dark: '#000000',
        light: '#FFFFFF'
      }
    });

    // Set response headers for image
    res.setHeader('Content-Type', 'image/png');
    res.setHeader('Content-Disposition', `inline; filename="emergency-qr-${emergencyUserId}.png"`);
    res.send(qrCodeBuffer);
  } catch (error) {
    console.error('❌ Error generating QR code:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Failed to generate QR code',
      error: error.message,
    });
  }
};

/**
 * Get QR code as data URL (base64)
 * Useful for mobile apps to display inline
 */
exports.getQRCodeDataUrl = async (req, res) => {
  try {
    const userId = req.user.userId;
    
    // Get emergency user ID from emergencyMed backend
    const emergencyUserId = await getEmergencyUserId(userId);
    
    if (!emergencyUserId) {
      return res.status(404).json({
        success: false,
        message: 'Emergency profile not found. Please sync your health profile first.',
      });
    }
    
    // Generate web profile URL
    const emergencyUrl = `${EMERGENCY_WEB_URL}/profile/${emergencyUserId}`;
    
    // Generate QR code as data URL
    const qrCodeDataUrl = await QRCode.toDataURL(emergencyUrl, {
      errorCorrectionLevel: 'H',
      width: 300,
      margin: 2,
      color: {
        dark: '#000000',
        light: '#FFFFFF'
      }
    });

    return res.status(200).json({
      success: true,
      qrCodeDataUrl: qrCodeDataUrl,
      emergencyUrl: emergencyUrl,
      emergencyUserId: emergencyUserId,
    });
  } catch (error) {
    console.error('❌ Error generating QR code data URL:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Failed to generate QR code',
      error: error.message,
    });
  }
};

/**
 * Display QR code in HTML page
 * Useful for web browsers
 */
exports.displayQRCodePage = async (req, res) => {
  try {
    const userId = req.user.userId;
    
    // Get emergency user ID from emergencyMed backend
    const emergencyUserId = await getEmergencyUserId(userId);
    
    if (!emergencyUserId) {
      return res.status(404).send(`
        <!DOCTYPE html>
        <html>
        <head><title>Profile Not Found</title></head>
        <body style="font-family: sans-serif; padding: 40px; text-align: center;">
          <h1>⚠️ Emergency Profile Not Found</h1>
          <p>Please sync your health profile first from the MediLinko app.</p>
        </body>
        </html>
      `);
    }
    
    // Generate web profile URL
    const emergencyUrl = `${EMERGENCY_WEB_URL}/profile/${emergencyUserId}`;
    
    // Generate QR code as data URL
    const qrCodeDataUrl = await QRCode.toDataURL(emergencyUrl, {
      errorCorrectionLevel: 'H',
      width: 400,
      margin: 3,
      color: {
        dark: '#000000',
        light: '#FFFFFF'
      }
    });

    // HTML page with QR code
    const html = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MediLinko - Emergency QR Code</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 20px;
            padding: 40px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            text-align: center;
            max-width: 500px;
            width: 100%;
        }
        .logo {
            font-size: 32px;
            font-weight: bold;
            color: #667eea;
            margin-bottom: 10px;
        }
        .subtitle {
            color: #666;
            font-size: 16px;
            margin-bottom: 30px;
        }
        .qr-container {
            background: #f8f9fa;
            border-radius: 15px;
            padding: 30px;
            margin: 20px 0;
            display: inline-block;
        }
        .qr-code {
            max-width: 100%;
            height: auto;
            border-radius: 10px;
        }
        .info {
            background: #e3f2fd;
            border-left: 4px solid #2196f3;
            padding: 15px;
            border-radius: 5px;
            margin: 20px 0;
            text-align: left;
        }
        .info-title {
            font-weight: bold;
            color: #1976d2;
            margin-bottom: 8px;
        }
        .info-text {
            color: #555;
            font-size: 14px;
            line-height: 1.6;
        }
        .emergency-url {
            background: #f5f5f5;
            padding: 10px;
            border-radius: 5px;
            font-family: monospace;
            font-size: 12px;
            word-break: break-all;
            color: #333;
            margin-top: 10px;
        }
        .buttons {
            margin-top: 30px;
            display: flex;
            gap: 10px;
            justify-content: center;
            flex-wrap: wrap;
        }
        .btn {
            padding: 12px 24px;
            border: none;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            transition: all 0.3s ease;
        }
        .btn-primary {
            background: #667eea;
            color: white;
        }
        .btn-primary:hover {
            background: #5568d3;
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
        }
        .btn-secondary {
            background: #f1f3f4;
            color: #333;
        }
        .btn-secondary:hover {
            background: #e8eaed;
        }
        @media print {
            body {
                background: white;
            }
            .container {
                box-shadow: none;
                padding: 20px;
            }
            .buttons {
                display: none;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo">🏥 MediLinko</div>
        <div class="subtitle">Emergency Medical QR Code</div>
        
        <div class="qr-container">
            <img src="${qrCodeDataUrl}" alt="Emergency QR Code" class="qr-code">
        </div>
        
        <div class="info">
            <div class="info-title">📱 How to Use</div>
            <div class="info-text">
                • Scan this QR code to access emergency medical information<br>
                • Responders can view vital health details instantly<br>
                • Keep this QR code accessible on your phone or wallet<br>
                • Emergency ID: <strong>${emergencyUserId}</strong>
            </div>
            <div class="emergency-url">
                <strong>Emergency URL:</strong><br>
                ${emergencyUrl}
            </div>
        </div>
        
        <div class="buttons">
            <button class="btn btn-primary" onclick="window.print()">
                🖨️ Print QR Code
            </button>
            <a href="${qrCodeDataUrl}" download="medilinko-emergency-qr.png" class="btn btn-secondary">
                💾 Download QR
            </a>
            <button class="btn btn-secondary" onclick="copyUrl()">
                📋 Copy URL
            </button>
        </div>
    </div>
    
    <script>
        function copyUrl() {
            const url = '${emergencyUrl}';
            navigator.clipboard.writeText(url).then(() => {
                alert('✅ Emergency URL copied to clipboard!');
            }).catch(() => {
                prompt('Copy this URL:', url);
            });
        }
    </script>
</body>
</html>
    `;

    res.setHeader('Content-Type', 'text/html');
    res.send(html);
  } catch (error) {
    console.error('❌ Error displaying QR code page:', error.message);
    return res.status(500).send(`
      <!DOCTYPE html>
      <html>
      <head><title>Error</title></head>
      <body style="font-family: sans-serif; padding: 40px; text-align: center;">
        <h1>❌ Error</h1>
        <p>Failed to generate QR code: ${error.message}</p>
      </body>
      </html>
    `);
  }
};
