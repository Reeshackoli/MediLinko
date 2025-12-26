const Prescription = require('../models/Prescription');
const User = require('../models/User');

// Create a new prescription
exports.createPrescription = async (req, res) => {
  try {
    const { patientId, type, content, diagnosis, notes } = req.body;
    const doctorId = req.user._id;

    // Validate required fields
    if (!patientId || !type || !content) {
      return res.status(400).json({
        success: false,
        message: 'Patient ID, type, and content are required'
      });
    }

    // Validate type
    if (!['text', 'image'].includes(type)) {
      return res.status(400).json({
        success: false,
        message: 'Type must be either "text" or "image"'
      });
    }

    // Verify patient exists
    const patient = await User.findById(patientId);
    if (!patient) {
      return res.status(404).json({
        success: false,
        message: 'Patient not found'
      });
    }

    // Create prescription
    const prescription = new Prescription({
      doctor: doctorId,
      patient: patientId,
      type,
      content,
      diagnosis: diagnosis || '',
      notes: notes || ''
    });

    await prescription.save();

    // Populate doctor and patient details
    await prescription.populate('doctor', 'fullName email');
    await prescription.populate('patient', 'fullName email');

    res.status(201).json({
      success: true,
      message: 'Prescription created successfully',
      prescription
    });
  } catch (error) {
    console.error('Create prescription error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create prescription',
      error: error.message
    });
  }
};

// Get all prescriptions for a doctor
exports.getDoctorPrescriptions = async (req, res) => {
  try {
    const doctorId = req.user._id;
    const { patientId } = req.query;

    const query = { doctor: doctorId };
    if (patientId) {
      query.patient = patientId;
    }

    const prescriptions = await Prescription.find(query)
      .populate('patient', 'fullName email phone')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      prescriptions
    });
  } catch (error) {
    console.error('Get doctor prescriptions error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch prescriptions',
      error: error.message
    });
  }
};

// Get all prescriptions for a patient
exports.getPatientPrescriptions = async (req, res) => {
  try {
    const patientId = req.user._id;
    const { doctorId } = req.query;

    const query = { patient: patientId };
    if (doctorId) {
      query.doctor = doctorId;
    }

    const prescriptions = await Prescription.find(query)
      .populate('doctor', 'fullName email phone')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      prescriptions
    });
  } catch (error) {
    console.error('Get patient prescriptions error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch prescriptions',
      error: error.message
    });
  }
};

// Get doctors who have prescribed to a patient
exports.getPatientDoctors = async (req, res) => {
  try {
    const patientId = req.user._id;

    const prescriptions = await Prescription.find({ patient: patientId })
      .populate('doctor', 'fullName email phone')
      .sort({ createdAt: -1 });

    // Get unique doctors
    const doctorsMap = new Map();
    prescriptions.forEach(prescription => {
      if (prescription.doctor && !doctorsMap.has(prescription.doctor._id.toString())) {
        doctorsMap.set(prescription.doctor._id.toString(), {
          _id: prescription.doctor._id,
          fullName: prescription.doctor.fullName,
          email: prescription.doctor.email,
          phone: prescription.doctor.phone,
          lastPrescriptionDate: prescription.createdAt
        });
      }
    });

    const doctors = Array.from(doctorsMap.values());

    res.json({
      success: true,
      doctors
    });
  } catch (error) {
    console.error('Get patient doctors error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch doctors',
      error: error.message
    });
  }
};

// Get doctor's patients (who have appointments or prescriptions)
exports.getDoctorPatients = async (req, res) => {
  try {
    const doctorId = req.user._id;
    console.log(`📋 Fetching patients for doctor: ${doctorId}`);

    const Appointment = require('../models/Appointment');
    
    // Get patients from appointments
    const appointments = await Appointment.find({
      doctorId: doctorId,
      status: { $in: ['approved', 'completed'] }
    })
      .populate('userId', 'fullName email phone')
      .sort({ date: -1 });

    console.log(`📊 Found ${appointments.length} appointments (approved/completed)`);

    // Get patients from prescriptions
    const prescriptions = await Prescription.find({ doctor: doctorId })
      .populate('patient', 'fullName email phone')
      .sort({ createdAt: -1 });

    console.log(`📝 Found ${prescriptions.length} prescriptions`);

    // Combine unique patients from both sources
    const patientsMap = new Map();
    
    // Add patients from appointments
    appointments.forEach(appointment => {
      if (appointment.userId && !patientsMap.has(appointment.userId._id.toString())) {
        patientsMap.set(appointment.userId._id.toString(), {
          _id: appointment.userId._id,
          fullName: appointment.userId.fullName,
          email: appointment.userId.email,
          phone: appointment.userId.phone,
          lastAppointmentDate: appointment.date
        });
      }
    });

    // Add patients from prescriptions
    prescriptions.forEach(prescription => {
      if (prescription.patient && !patientsMap.has(prescription.patient._id.toString())) {
        patientsMap.set(prescription.patient._id.toString(), {
          _id: prescription.patient._id,
          fullName: prescription.patient.fullName,
          email: prescription.patient.email,
          phone: prescription.patient.phone,
          lastPrescriptionDate: prescription.createdAt
        });
      }
    });

    const patients = Array.from(patientsMap.values());
    console.log(`👥 Returning ${patients.length} unique patients`);

    res.json({
      success: true,
      patients
    });
  } catch (error) {
    console.error('❌ Get doctor patients error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch patients',
      error: error.message
    });
  }
};
