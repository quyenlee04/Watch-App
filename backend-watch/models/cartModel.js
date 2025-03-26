const pool = require('../config/dbConfig');

class CartModel {
    static async getCartItems(userId) {
        const [items] = await pool.promise().query(
            `SELECT c.*, p.name, p.price, p.image_url 
             FROM cart c 
             JOIN products p ON c.product_id = p.id 
             WHERE c.user_id = ?`,
            [userId]
        );
        return items;
    }

    static async getCartItemById(cartId, userId) {
        const [items] = await pool.promise().query(
            `SELECT c.*, p.name, p.price, p.image_url 
             FROM cart c 
             JOIN products p ON c.product_id = p.id 
             WHERE c.id = ? AND c.user_id = ?`,
            [cartId, userId]
        );
        return items.length ? items[0] : null;
    }

    static async addToCart(cartData) {
        const { user_id, product_id, quantity } = cartData;
        
        const [result] = await pool.promise().query(
            'INSERT INTO cart (user_id, product_id, quantity) VALUES (?, ?, ?)',
            [user_id, product_id, quantity]
        );
        
        return result.insertId;
    }

    static async updateCartItem(cartId, quantity) {
        const [result] = await pool.promise().query(
            'UPDATE cart SET quantity = ? WHERE id = ?',
            [quantity, cartId]
        );
        return result.affectedRows;
    }

    static async removeCartItem(cartId) {
        const [result] = await pool.promise().query(
            'DELETE FROM cart WHERE id = ?',
            [cartId]
        );
        return result.affectedRows;
    }

    static async clearCart(userId) {
        const [result] = await pool.promise().query(
            'DELETE FROM cart WHERE user_id = ?',
            [userId]
        );
        return result.affectedRows;
    }
}

module.exports = CartModel;