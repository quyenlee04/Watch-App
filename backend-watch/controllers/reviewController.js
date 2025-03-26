const ReviewModel = require('../models/reviewModel');

// Add a review for a product
exports.addReview = async (req, res) => {
    try {
        const { product_id, rating, comment } = req.body;
        const userId = req.user.id;

        const reviewId = await ReviewModel.create({
            product_id,
            user_id: userId,
            rating,
            comment
        });

        res.status(201).json({ 
            message: 'Review added successfully', 
            reviewId 
        });
    } catch (error) {
        console.error('Error adding review:', error);
        res.status(500).json({ message: error.message });
    }
};

// Get all reviews for a product
exports.getProductReviews = async (req, res) => {
    try {
        const { product_id } = req.params;
        const reviews = await ReviewModel.getProductReviews(product_id);
        res.status(200).json(reviews);
    } catch (error) {
        console.error('Error fetching reviews:', error);
        res.status(500).json({ message: error.message });
    }
};