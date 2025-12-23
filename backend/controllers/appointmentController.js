const Appointment = require('../models/Appointment');
const User = require('../models/User');
const DoctorProfile = require('../models/DoctorProfile');
const Notification = require('../models/Notification');
const HealthProfile = require('../models/HealthProfile');
const { sendNotificationToUser } = require('./notificationController');

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

    // Send FCM notification to doctor
    try {
      const patientName = appointment.userId.fullName || 'A patient';
      console.log(`📱 Attempting to send FCM notification to doctor: ${doctorId}`);
      
      const notificationResult = await sendNotificationToUser(doctorId, {
        title: '🔔 New Appointment Request',
        body: `${patientName} has requested an appointment on ${date} at ${time}`,
        data: {
          type: 'appointment',
          appointmentId: appointment._id.toString(),
          patientId: userId.toString(),
          date,
          time,
        },
      });
      
      if (notificationResult.success) {
        console.log('✅ FCM notification sent to doctor successfully');
      } else {
        console.error('⚠️ FCM notification failed:', notificationResult.message || notificationResult.error);
      }
    } catch (fcmError) {
      console.error('⚠️ Exception sending FCM notification:', fcmError.message);
      // Don't fail the request if FCM fails
    }

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

    // Fetch health profiles for all patients in one query
    const userIds = appointments.map(apt => apt.userId._id);
    const healthProfiles = await HealthProfile.find({ userId: { $in: userIds } }).lean();
    
    // Create a map for quick lookup
    const profileMap = {};
    healthProfiles.forEach(profile => {
      profileMap[profile.userId.toString()] = profile;
    });

    // Attach health profile to each appointment
    const enrichedAppointments = appointments.map(apt => {
      const healthProfile = profileMap[apt.userId._id.toString()];
      return {
        ...apt,
        patientProfile: healthProfile ? {
          age: healthProfile.age,
          gender: healthProfile.gender,
          city: healthProfile.city,
          bloodGroup: healthProfile.bloodGroup,
          allergies: healthProfile.allergies || [],
          medicalConditions: healthProfile.medicalConditions || [],
          currentMedications: healthProfile.currentMedications || [],
          emergencyContactName: healthProfile.emergencyContactName,
          emergencyContactRelationship: healthProfile.emergencyContactRelationship,
          emergencyContactPhone: healthProfile.emergencyContactPhone,
        } : null,
      };
    });

    console.log(`✅ Fetched ${enrichedAppointments.length} appointments with patient profiles`);

    res.json({
      success: true,
      count: enrichedAppointments.length,
      appointments: enrichedAppointments,
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
// @route   PATCH /api/appointments/:id/status
// @access  Private
exports.updateAppointmentStatus = async (req, res) => {
  try {
    const userId = req.user._id || req.user.id;
    const { id } = req.params;
    const { status, reason } = req.body;

    console.log('📝 Update appointment status request:');
    console.log('   Appointment ID:', id);
    console.log('   User ID:', userId);
    console.log('   New Status:', status);
    console.log('   Reason:', reason);

    const validStatuses = ['pending', 'approved', 'rejected', 'cancelled'];
    if (!validStatuses.includes(status)) {
      console.log('❌ Invalid status:', status);
      return res.status(400).json({
        success: false,
        message: 'Invalid status',
      });
    }

    const appointment = await Appointment.findById(id);

    if (!appointment) {
      console.log('❌ Appointment not found:', id);
      return res.status(404).json({
        success: false,
        message: 'Appointment not found',
      });
    }

    console.log('✅ Appointment found:', {
      appointmentId: appointment._id,
      doctorId: appointment.doctorId,
      userId: appointment.userId,
      currentStatus: appointment.status,
    });

    const isDoctor = appointment.doctorId.toString() === userId.toString();
    const isPatient = appointment.userId.toString() === userId.toString();

    console.log('🔐 Authorization check:', { isDoctor, isPatient });

    if (!isDoctor && !isPatient) {
      console.log('❌ Not authorized');
      return res.status(403).json({
        success: false,
        message: 'Not authorized',
      });
    }

    if (isDoctor && !['approved', 'rejected'].includes(status)) {
      console.log('❌ Doctor can only approve or reject');
      return res.status(400).json({
        success: false,
        message: 'Doctors can only approve or reject',
      });
    }

    if (isPatient && status !== 'cancelled') {
      console.log('❌ Patient can only cancel');
      return res.status(400).json({
        success: false,
        message: 'Patients can only cancel',
      });
    }

    // If cancelled or rejected, delete the appointment instead of keeping it
    if (status === 'cancelled' || status === 'rejected') {
      console.log(`🗑️ Deleting ${status} appointment`);
      
      // First populate for notification before deletion
      await appointment.populate('userId', 'fullName email phone');
      await appointment.populate('doctorId', 'fullName email phone specialization clinicName');
      
      // Send notification to patient if rejected by doctor
      if (status === 'rejected' && isDoctor) {
        try {
          const doctorName = appointment.doctorId.fullName || 'Doctor';
          const notificationMessage = reason 
            ? `Your appointment with Dr. ${doctorName} on ${appointment.date} at ${appointment.time} has been rejected. Reason: ${reason}`
            : `Your appointment with Dr. ${doctorName} on ${appointment.date} at ${appointment.time} has been rejected.`;

          // Save to database
          await Notification.create({
            userId: appointment.userId._id,
            title: 'Appointment Rejected',
            message: notificationMessage,
            type: 'appointment',
            relatedId: appointment._id,
            relatedModel: 'Appointment',
            data: {
              appointmentId: appointment._id,
              doctorName,
              date: appointment.date,
              time: appointment.time,
              status: 'rejected',
              reason: reason || null,
            },
          });

          // Send FCM notification
          console.log(`📱 Sending rejection notification to patient: ${appointment.userId._id}`);
          const rejectResult = await sendNotificationToUser(appointment.userId._id, {
            title: '❌ Appointment Rejected',
            body: reason 
              ? `Dr. ${doctorName} rejected your appointment. Reason: ${reason}`
              : `Dr. ${doctorName} rejected your appointment on ${appointment.date} at ${appointment.time}`,
            data: {
              type: 'appointment',
              status: 'rejected',
              appointmentId: appointment._id.toString(),
              doctorId: appointment.doctorId._id.toString(),
              date: appointment.date,
              time: appointment.time,
              reason: reason || '',
            },
          });

          if (rejectResult.success) {
            console.log('✅ Rejection notification sent to patient successfully');
          } else {
            console.error('⚠️ Rejection notification failed:', rejectResult.message);
          }
        } catch (notifError) {
          console.error('⚠️ Failed to send rejection notification:', notifError);
        }
      }
      
      // Delete the appointment
      await Appointment.findByIdAndDelete(id);
      console.log(`✅ ${status.charAt(0).toUpperCase() + status.slice(1)} appointment deleted successfully`);
      
      return res.json({
        success: true,
        message: `Appointment ${status} and removed`,
      });
    }

    // Update appointment status for other statuses (only approved now)
    appointment.status = status;
    if (reason) {
      appointment.rejectionReason = reason;
    }
    await appointment.save();

    console.log('✅ Appointment status updated successfully');

    // Populate appointment details
    await appointment.populate('userId', 'fullName email phone');
    await appointment.populate('doctorId', 'fullName email phone specialization clinicName');

    // Create notification for approved appointments
    if (status === 'approved' && isDoctor) {
      try {
        const doctorName = appointment.doctorId.fullName || 'Doctor';
        await Notification.create({
          userId: appointment.userId._id,
          title: 'Appointment Approved',
          message: `Your appointment with Dr. ${doctorName} on ${appointment.date} at ${appointment.time} has been approved.`,
          type: 'appointment',
          relatedId: appointment._id,
          relatedModel: 'Appointment',
          data: {
            appointmentId: appointment._id,
            doctorName,
            date: appointment.date,
            time: appointment.time,
            status: 'approved',
          },
        });

        // Send FCM notification
        console.log(`📱 Sending approval notification to patient: ${appointment.userId._id}`);
        const approvalResult = await sendNotificationToUser(appointment.userId._id, {
          title: '✅ Appointment Approved',
          body: `Dr. ${doctorName} approved your appointment on ${appointment.date} at ${appointment.time}`,
          data: {
            type: 'appointment',
            status: 'approved',
            appointmentId: appointment._id.toString(),
            doctorId: appointment.doctorId._id.toString(),
            date: appointment.date,
            time: appointment.time,
          },
        });

        if (approvalResult.success) {
          console.log('✅ Approval notification sent to patient successfully');
        } else {
          console.error('⚠️ Approval notification failed:', approvalResult.message);
        }
      } catch (notifError) {
        console.error('⚠️ Failed to create notification:', notifError);
      }
    }

    res.json({
      success: true,
      message: `Appointment ${status} successfully`,
      appointment,
    });
  } catch (error) {
    console.error('❌ Error updating appointment:', error);
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

    // Get unique patient count
    const uniquePatients = await Appointment.distinct('userId', { doctorId });
    const totalPatients = uniquePatients.length;

    // Stats calculated

    res.json({
      success: true,
      stats: {
        total: totalCount,
        today: todayCount,
        pending: pendingCount,
        approved: approvedCount,
        totalPatients: totalPatients,
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
