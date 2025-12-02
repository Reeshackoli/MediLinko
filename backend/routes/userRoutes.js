const express = require('express');
const {
  getDoctors,
  getPharmacies,
  getDoctorById,
  getPharmacyById,
  getNearbyDoctors
} = require('../controllers/userController');

const router = express.Router();

router.get('/doctors/nearby', getNearbyDoctors);
router.get('/doctors', getDoctors);
router.get('/doctors/:id', getDoctorById);
router.get('/pharmacies', getPharmacies);
router.get('/pharmacies/:id', getPharmacyById);

module.exports = router;
