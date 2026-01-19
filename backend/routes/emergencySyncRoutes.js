const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const emergencySyncController = require('../controllers/emergencySyncController');

/**
 * @route   POST /api/emergency/sync
 * @desc    Sync emergency data to emergencyMed service
 * @access  Private
 */
router.post('/sync', auth, emergencySyncController.syncEmergencyData);

/**
 * @route   GET /api/emergency/qr-url
 * @desc    Get QR URL for emergency profile
 * @access  Private
 */
router.get('/qr-url', auth, emergencySyncController.getQRUrl);

/**
 * @route   GET /api/emergency/service-status
 * @desc    Check emergencyMed service health
 * @access  Private
 */
router.get('/service-status', auth, emergencySyncController.checkEmergencyService);

module.exports = router;
