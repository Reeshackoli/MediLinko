const express = require('express');
const {
  submitRating,
  getRatings,
  getAverageRating,
  canRate
} = require('../controllers/ratingController');
const { protect } = require('../middleware/auth');

const router = express.Router();

// Submit a new rating (requires auth)
router.post('/', protect, submitRating);

// Get all ratings for a user (public)
router.get('/:userId', getRatings);

// Get average rating for a user (public)
router.get('/:userId/average', getAverageRating);

// Check if current user can rate target (requires auth)
router.get('/can-rate/:targetUserId', protect, canRate);

module.exports = router;
