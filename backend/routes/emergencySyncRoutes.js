const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');

// Load controller with error handling
let emergencySyncController;
try {
  emergencySyncController = require('../controllers/emergencySyncController');
  console.log('✅ emergencySyncController loaded. Functions:', Object.keys(emergencySyncController));
} catch (error) {
  console.error('❌ Failed to load emergencySyncController:', error.message);
  emergencySyncController = {};
}

/**
 * @route   POST /api/emergency/sync
 * @desc    Sync emergency data to emergencyMed service
 * @access  Private
 */
router.post('/sync', protect, emergencySyncController.syncEmergencyData || ((req, res) => res.status(503).json({ error: 'Service unavailable' })));

/**
 * @route   GET /api/emergency/qr-url
 * @desc    Get QR URL for emergency profile
 * @access  Private
 */
router.get('/qr-url', protect, emergencySyncController.getQRUrl || ((req, res) => res.status(503).json({ error: 'Service unavailable' })));

/**
 * @route   GET /api/emergency/service-status
 * @desc    Check emergencyMed service health
 * @access  Private
 */
router.get('/service-status', protect, emergencySyncController.checkEmergencyService || ((req, res) => res.status(503).json({ error: 'Service unavailable' })));

/**
 * @route   GET /api/emergency/qr-code
 * @desc    Generate QR code as PNG image
 * @access  Private
 */
router.get('/qr-code', protect, emergencySyncController.generateQRCode || ((req, res) => res.status(503).json({ error: 'Service unavailable' })));

/**
 * @route   GET /api/emergency/qr-data
 * @desc    Get QR code as base64 data URL (for mobile apps)
 * @access  Private
 */
router.get('/qr-data', protect, emergencySyncController.getQRCodeDataUrl || ((req, res) => res.status(503).json({ error: 'Service unavailable' })));

/**
 * @route   GET /api/emergency/qr-display
 * @desc    Display QR code in HTML page (for web browsers)
 * @access  Private
 */
router.get('/qr-display', protect, emergencySyncController.displayQRCodePage || ((req, res) => res.status(503).json({ error: 'Service unavailable' })));

module.exports = router;
