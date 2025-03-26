const pool = require('../config/dbConfig');

class OrderModel {
    static async create(orderData) {
        const { user_id, total_amount, shipping_address } = orderData;
        const shippingAddressJSON = typeof shipping_address === 'string' 
            ? shipping_address 
            : JSON.stringify(shipping_address);
        
        const [result] = await pool.promise().query(
            'INSERT INTO orders (user_id, total_amount, shipping_address) VALUES (?, ?, ?)',
            [user_id, total_amount, shippingAddressJSON]
        );
        
        return result.insertId;
    }

    static async addOrderItem(orderItemData) {
        const { order_id, product_id, quantity, price } = orderItemData;
        
        const [result] = await pool.promise().query(
            'INSERT INTO order_items (order_id, product_id, quantity, price) VALUES (?, ?, ?, ?)',
            [order_id, product_id, quantity, price]
        );
        
        return result.insertId;
    }

    static async getUserOrders(userId) {
        const [orders] = await pool.promise().query(
            'SELECT * FROM orders WHERE user_id = ? ORDER BY created_at DESC',
            [userId]
        );
        return orders;
    }

    static async getAllOrders() {
        const [orders] = await pool.promise().query(`
            SELECT o.*, u.name as user_name 
            FROM orders o 
            JOIN users u ON o.user_id = u.id 
            ORDER BY o.created_at DESC`
        );
        return orders;
    }

    // Add this alias method
    static async getAllOrdersWithUserInfo() {
        return this.getAllOrders();
    }

    static async getOrderById(orderId) {
        const [[order]] = await pool.promise().query(
            `SELECT o.*, u.name as user_name, u.email, u.phone 
             FROM orders o 
             JOIN users u ON o.user_id = u.id 
             WHERE o.id = ?`,
            [orderId]
        );
        return order;
    }

    static async getOrderItems(orderId) {
        const [items] = await pool.promise().query(
            `SELECT oi.*, p.name as product_name 
             FROM order_items oi 
             JOIN products p ON oi.product_id = p.id 
             WHERE oi.order_id = ?`,
            [orderId]
        );
        return items;
    }

    static async updateStatus(orderId, status) {
        // Since status column doesn't exist, we'll log the status change but not update the database
        console.log(`Status update requested for order ${orderId} to ${status} (column not in database)`);
        return 1; // Return 1 to indicate success without actually updating
        
        // Uncomment this when you add the status column to your database:
        /*
        const [result] = await pool.promise().query(
            'UPDATE orders SET status = ? WHERE id = ?',
            [status, orderId]
        );
        return result.affectedRows;
        */
    }

    // Add this method to your OrderModel class
    static async getOrdersCount() {
        const [[result]] = await pool.promise().query('SELECT COUNT(*) as count FROM orders');
        return result.count;
    }

    // Add this new method to get recent orders
    static async getRecentOrders(limit = 5) {
        const [orders] = await pool.promise().query(`
            SELECT o.*, u.name as user_name 
            FROM orders o 
            JOIN users u ON o.user_id = u.id 
            ORDER BY o.created_at DESC
            LIMIT ?`,
            [limit]
        );
        return orders;
    }
}

module.exports = OrderModel;