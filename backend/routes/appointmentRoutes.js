const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const {
  bookAppointment,
  getUserAppointments,
  getDoctorAppointments,
  getAppointmentById,
  updateAppointmentStatus,
  getAvailableSlots,
  getAppointmentStats,
} = require('../controllers/appointmentController');

// Public routes
router.get('/slots', getAvailableSlots);

// Protected routes
router.post('/book', protect, bookAppointment);
router.get('/', protect, getUserAppointments);
router.get('/doctor', protect, getDoctorAppointments);
router.get('/stats', protect, getAppointmentStats);
router.get('/:id', protect, getAppointmentById);
router.patch('/:id/status', protect, updateAppointmentStatus);

module.exports = router;
