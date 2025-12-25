const Rating = require('../models/Rating');
const DoctorProfile = require('../models/DoctorProfile');
const PharmacistProfile = require('../models/PharmacistProfile');
const User = require('../models/User');

// @desc    Submit a rating for a doctor/pharmacist
// @route   POST /api/ratings
// @access  Private
exports.submitRating = async (req, res) => {
  try {
    const { targetUserId, rating, review, appointmentId, serviceType } = req.body;
    const ratedByUserId = req.user._id;

    // Validate rating value
    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({
        success: false,
        message: 'Rating must be between 1 and 5'
      });
    }

    // Check if target user exists and is a doctor or pharmacist
    const targetUser = await User.findById(targetUserId);
    if (!targetUser) {
      return res.status(404).json({
        success: false,
        message: 'Target user not found'
      });
    }

    if (!['doctor', 'pharmacist'].includes(targetUser.role)) {
      return res.status(400).json({
        success: false,
        message: 'Can only rate doctors and pharmacists'
      });
    }

    // Check if user already rated this appointment
    if (appointmentId) {
      const existingRating = await Rating.findOne({
        targetUserId,
        ratedByUserId,
        appointmentId
      });

      if (existingRating) {
        // Update existing rating
        existingRating.rating = rating;
        existingRating.review = review;
        await existingRating.save();

        // Recalculate average
        await updateAverageRating(targetUserId, targetUser.role);

        return res.status(200).json({
          success: true,
          message: 'Rating updated successfully',
          data: existingRating
        });
      }
    }

    // Create new rating
    const newRating = await Rating.create({
      targetUserId,
      ratedByUserId,
      appointmentId,
      rating,
      review,
      serviceType: serviceType || 'general'
    });

    // Update average rating
    await updateAverageRating(targetUserId, targetUser.role);

    res.status(201).json({
      success: true,
      message: 'Rating submitted successfully',
      data: newRating
    });
  } catch (error) {
    console.error('Error submitting rating:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Get ratings for a doctor/pharmacist
// @route   GET /api/ratings/:userId
// @access  Public
exports.getRatings = async (req, res) => {
  try {
    const { userId } = req.params;
    const { limit = 10, page = 1 } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const ratings = await Rating.find({ targetUserId: userId })
      .populate('ratedByUserId', 'fullName')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const { averageRating, totalRatings } = await Rating.calculateAverageRating(userId);

    res.status(200).json({
      success: true,
      data: {
        ratings,
        averageRating,
        totalRatings,
        page: parseInt(page),
        limit: parseInt(limit)
      }
    });
  } catch (error) {
    console.error('Error fetching ratings:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Get average rating for a user
// @route   GET /api/ratings/:userId/average
// @access  Public
exports.getAverageRating = async (req, res) => {
  try {
    const { userId } = req.params;
    const { averageRating, totalRatings } = await Rating.calculateAverageRating(userId);

    res.status(200).json({
      success: true,
      data: {
        averageRating,
        totalRatings
      }
    });
  } catch (error) {
    console.error('Error fetching average rating:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// @desc    Check if user can rate a target
// @route   GET /api/ratings/can-rate/:targetUserId
// @access  Private
exports.canRate = async (req, res) => {
  try {
    const { targetUserId } = req.params;
    const { appointmentId } = req.query;
    const ratedByUserId = req.user._id;

    // Check if already rated
    const query = { targetUserId, ratedByUserId };
    if (appointmentId) {
      query.appointmentId = appointmentId;
    }

    const existingRating = await Rating.findOne(query);

    res.status(200).json({
      success: true,
      data: {
        canRate: !existingRating,
        existingRating: existingRating || null
      }
    });
  } catch (error) {
    console.error('Error checking rate eligibility:', error);
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};

// Helper function to update average rating in profile
async function updateAverageRating(userId, role) {
  const { averageRating, totalRatings } = await Rating.calculateAverageRating(userId);

  if (role === 'doctor') {
    await DoctorProfile.findOneAndUpdate(
      { userId },
      { rating: averageRating, totalRatings }
    );
  } else if (role === 'pharmacist') {
    await PharmacistProfile.findOneAndUpdate(
      { userId },
      { rating: averageRating, totalRatings }
    );
  }
}
