const express = require('express');
const { 
  updateProfile, 
  getProfile, 
  updateWizardStep 
} = require('../controllers/profileController');
const { protect } = require('../middleware/auth');

const router = express.Router();

router.route('/')
  .get(protect, getProfile)
  .put(protect, updateProfile);

router.patch('/wizard', protect, updateWizardStep);

module.exports = router;
