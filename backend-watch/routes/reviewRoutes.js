const express = require('express');
const reviewController = require('../controllers/reviewController');
const { authenticate } = require('../middleware/auth'); // Assuming you have an authentication middleware
const router = express.Router();

router.post('/', authenticate, reviewController.addReview);
router.get('/:product_id', reviewController.getProductReviews);

module.exports = router;