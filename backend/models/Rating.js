const mongoose = require('mongoose');

const ratingSchema = new mongoose.Schema({
  // Doctor or Pharmacist being rated
  targetUserId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  // User who gave the rating
  ratedByUserId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  // Related appointment (optional)
  appointmentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Appointment'
  },
  // Rating value 1-5
  rating: {
    type: Number,
    required: true,
    min: 1,
    max: 5
  },
  // Optional review text
  review: {
    type: String,
    trim: true,
    maxLength: 500
  },
  // Type of service being rated
  serviceType: {
    type: String,
    enum: ['consultation', 'appointment', 'pharmacy', 'general'],
    default: 'general'
  }
}, {
  timestamps: true
});

// Compound index to prevent duplicate ratings
ratingSchema.index({ targetUserId: 1, ratedByUserId: 1, appointmentId: 1 }, { unique: true });

// Static method to calculate average rating for a user
ratingSchema.statics.calculateAverageRating = async function(targetUserId) {
  const result = await this.aggregate([
    { $match: { targetUserId: new mongoose.Types.ObjectId(targetUserId) } },
    {
      $group: {
        _id: '$targetUserId',
        averageRating: { $avg: '$rating' },
        totalRatings: { $sum: 1 }
      }
    }
  ]);

  if (result.length > 0) {
    return {
      averageRating: Math.round(result[0].averageRating * 10) / 10, // Round to 1 decimal
      totalRatings: result[0].totalRatings
    };
  }

  return { averageRating: 0, totalRatings: 0 };
};

module.exports = mongoose.model('Rating', ratingSchema);
