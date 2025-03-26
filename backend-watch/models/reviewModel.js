const pool = require('../config/dbConfig');

class ReviewModel {
    static async create(reviewData) {
        const { product_id, user_id, rating, comment } = reviewData;
        
        const [result] = await pool.promise().query(
            'INSERT INTO reviews (product_id, user_id, rating, comment) VALUES (?, ?, ?, ?)',
            [product_id, user_id, rating, comment]
        );
        
        return result.insertId;
    }

    static async getProductReviews(productId) {
        const [reviews] = await pool.promise().query(
            'SELECT r.*, u.name FROM reviews r JOIN users u ON r.user_id = u.id WHERE r.product_id = ?',
            [productId]
        );
        return reviews;
    }
}

module.exports = ReviewModel;