const Appointment = require('../models/Appointment');
const User = require('../models/User');
const DoctorProfile = require('../models/DoctorProfile');

// @desc    Book a new appointment
// @route   POST /api/appointments/book
// @access  Private (User)
exports.bookAppointment = async (req, res) => {
  try {
    const userId = req.user._id || req.user.id;
    const { doctorId, date, time, symptoms } = req.body;

    // Appointment booking - logging disabled to reduce memory

    if (!doctorId || !date || !time) {
      return res.status(400).json({
        success: false,
        message: 'Doctor ID, date, and time are required',
      });
    }

    const doctor = await User.findById(doctorId);
    if (!doctor || doctor.role !== 'doctor') {
      return res.status(404).json({
        success: false,
        message: 'Doctor not found',
      });
    }

    if (userId === doctorId) {
      return res.status(400).json({
        success: false,
        message: 'Cannot book appointment with yourself',
      });
    }

    const existingAppointment = await Appointment.findOne({
      doctorId,
      date,
      time,
      status: { $ne: 'cancelled' },
    });

    if (existingAppointment) {
      return res.status(409).json({
        success: false,
        message: 'This time slot is already booked',
      });
    }

    const appointment = await Appointment.create({
      userId,
      doctorId,
      date,
      time,
      symptoms: symptoms || '',
      status: 'pending',
    });

    await appointment.populate('userId', 'fullName email phone');
    await appointment.populate('doctorId', 'fullName email specialization clinicName consultationFee');

    res.status(201).json({
      success: true,
      message: 'Appointment booked successfully',
      appointment,
    });
  } catch (error) {
    console.error('Error booking appointment:', error);
    res.status(500).json({
      success: false,
      message: 'Server error while booking appointment',
      error: error.message,
    });
  }
};

// @desc    Get user's appointments
// @route   GET /api/appointments
// @access  Private (User)
exports.getUserAppointments = async (req, res) => {
  try {
    const userId = req.user._id || req.user.id;
    const { status } = req.query;

    const filter = { userId };
    if (status) {
      filter.status = status;
    }

    const appointments = await Appointment.find(filter)
      .populate('doctorId', 'fullName email phone specialization clinicName clinicAddress consultationFee clinicLatitude clinicLongitude')
      .sort({ date: -1, time: -1 });

    res.json({
      success: true,
      count: appointments.length,
      appointments,
    });
  } catch (error) {
    console.error('Error fetching user appointments:', error);
    res.status(500).json({
      success: false,
      message: 'Server error while fetching appointments',
      error: error.message,
    });
  }
};

// @desc    Get doctor's appointments
// @route   GET /api/appointments/doctor
// @access  Private (Doctor)
exports.getDoctorAppointments = async (req, res) => {
  try {
    const doctorId = req.user._id || req.user.id;
    const { status, date } = req.query;

    const doctor = await User.findById(doctorId);
    if (!doctor || doctor.role !== 'doctor') {
      return res.status(403).json({
        success: false,
        message: 'Access denied. Doctor role required',
      });
    }

    const filter = { doctorId };
    if (status) {
      filter.status = status;
    }
    if (date) {
      filter.date = date;
    }

    const appointments = await Appointment.find(filter)
      .populate('userId', 'fullName email phone')
      .sort({ date: 1, time: 1 })
      .lean();

    // Doctor appointments fetched

    res.json({
      success: true,
      count: appointments.length,
      appointments,
    });
  } catch (error) {
    console.error('Error fetching doctor appointments:', error);
    res.status(500).json({
      success: false,
      message: 'Server error while fetching appointments',
      error: error.message,
    });
  }
};

// @desc    Get appointment by ID
// @route   GET /api/appointments/:id
// @access  Private
exports.getAppointmentById = async (req, res) => {
  try {
    const userId = req.user._id || req.user.id;
    const { id } = req.params;

    const appointment = await Appointment.findById(id)
      .populate('userId', 'fullName email phone')
      .populate('doctorId', 'fullName email phone specialization clinicName clinicAddress consultationFee');

    if (!appointment) {
      return res.status(404).json({
        success: false,
        message: 'Appointment not found',
      });
    }

    if (
      appointment.userId._id.toString() !== userId &&
      appointment.doctorId._id.toString() !== userId
    ) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to view this appointment',
      });
    }

    res.json({
      success: true,
      appointment,
    });
  } catch (error) {
    console.error('Error fetching appointment:', error);
    res.status(500).json({
      success: false,
      message: 'Server error while fetching appointment',
      error: error.message,
    });
  }
};

// @desc    Update appointment status
// @route   PUT /api/appointments/:id/status
// @access  Private
exports.updateAppointmentStatus = async (req, res) => {
  try {
    const userId = req.user._id || req.user.id;
    const { id } = req.params;
    const { status } = req.body;

    const validStatuses = ['pending', 'approved', 'rejected', 'cancelled'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid status',
      });
    }

    const appointment = await Appointment.findById(id);

    if (!appointment) {
      return res.status(404).json({
        success: false,
        message: 'Appointment not found',
      });
    }

    const isDoctor = appointment.doctorId.toString() === userId;
    const isPatient = appointment.userId.toString() === userId;

    if (!isDoctor && !isPatient) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized',
      });
    }

    if (isDoctor && !['approved', 'rejected'].includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Doctors can only approve or reject',
      });
    }

    if (isPatient && status !== 'cancelled') {
      return res.status(400).json({
        success: false,
        message: 'Patients can only cancel',
      });
    }

    appointment.status = status;
    await appointment.save();

    await appointment.populate('userId', 'fullName email phone');
    await appointment.populate('doctorId', 'fullName email phone specialization clinicName');

    res.json({
      success: true,
      message: `Appointment ${status} successfully`,
      appointment,
    });
  } catch (error) {
    console.error('Error updating appointment:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message,
    });
  }
};

// @desc    Get available time slots
// @route   GET /api/appointments/slots
// @access  Public
exports.getAvailableSlots = async (req, res) => {
  try {
    const { doctorId, date } = req.query;

    if (!doctorId || !date) {
      return res.status(400).json({
        success: false,
        message: 'Doctor ID and date required',
      });
    }

    const doctorProfile = await DoctorProfile.findOne({ userId: doctorId })
      .select('availableTimings') // Only fetch availableTimings field
      .lean(); // Convert to plain JS object for better performance
    
    if (!doctorProfile || !doctorProfile.availableTimings || doctorProfile.availableTimings.length === 0) {
      return res.json({
        success: true,
        slots: [],
        message: 'No availability configured',
      });
    }

    const dateObj = new Date(date);
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    const dayName = days[dateObj.getDay()];

    const dayTiming = doctorProfile.availableTimings.find(t => t.day === dayName);
    if (!dayTiming) {
      return res.json({
        success: true,
        slots: [],
        message: `Not available on ${dayName}`,
      });
    }

    const slots = [];
    const [fromHour, fromMin] = dayTiming.from.split(':').map(Number);
    const [toHour, toMin] = dayTiming.to.split(':').map(Number);

    let currentHour = fromHour;
    let currentMin = fromMin;

    while (currentHour < toHour || (currentHour === toHour && currentMin < toMin)) {
      const timeSlot = `${String(currentHour).padStart(2, '0')}:${String(currentMin).padStart(2, '0')}`;
      slots.push(timeSlot);

      currentMin += 30;
      if (currentMin >= 60) {
        currentMin -= 60;
        currentHour += 1;
      }
    }

    const bookedAppointments = await Appointment.find({
      doctorId,
      date,
      status: { $ne: 'cancelled' },
    })
    .select('time') // Only fetch time field
    .lean(); // Convert to plain JS object

    const bookedTimes = bookedAppointments.map(apt => apt.time);
    const availableSlots = slots.filter(slot => !bookedTimes.includes(slot));

    res.json({
      success: true,
      date,
      day: dayName,
      totalSlots: slots.length,
      availableSlots,
      bookedSlots: bookedTimes,
    });
  } catch (error) {
    console.error('Error fetching slots:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message,
    });
  }
};

// @desc    Get doctor appointment statistics
// @route   GET /api/appointments/stats
// @access  Private (Doctor)
exports.getAppointmentStats = async (req, res) => {
  try {
    const doctorId = req.user._id || req.user.id;

    const doctor = await User.findById(doctorId);
    if (!doctor || doctor.role !== 'doctor') {
      return res.status(403).json({
        success: false,
        message: 'Doctor role required',
      });
    }

    const today = new Date().toISOString().split('T')[0];
    // Stats calculation

    const [totalCount, todayCount, pendingCount, approvedCount] = await Promise.all([
      Appointment.countDocuments({ doctorId }),
      Appointment.countDocuments({ doctorId, date: today }),
      Appointment.countDocuments({ doctorId, status: 'pending' }),
      Appointment.countDocuments({ doctorId, status: 'approved' }),
    ]);

    // Stats calculated

    res.json({
      success: true,
      stats: {
        total: totalCount,
        today: todayCount,
        pending: pendingCount,
        approved: approvedCount,
      },
    });
  } catch (error) {
    console.error('Error fetching stats:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message,
    });
  }
};
