const express = require('express');
const router = express.Router();
const prescriptionController = require('../controllers/prescriptionController');
const { protect } = require('../middleware/auth');

// All routes require authentication
router.use(protect);

// Doctor routes
router.post('/', prescriptionController.createPrescription);
router.get('/doctor', prescriptionController.getDoctorPrescriptions);
router.get('/doctor/patients', prescriptionController.getDoctorPatients);

// Patient routes
router.get('/patient', prescriptionController.getPatientPrescriptions);
router.get('/patient/doctors', prescriptionController.getPatientDoctors);

module.exports = router;
