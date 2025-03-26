const OrderModel = require('../models/orderModel');
const ProductModel = require('../models/productModel');
const CartModel = require('../models/cartModel');
const pool = require('../config/dbConfig');

exports.createOrder = async (req, res) => {
    // Start transaction
    const connection = await pool.promise().getConnection();
    await connection.beginTransaction();

    try {
        const { items, total_amount, shipping_address } = req.body;
        const userId = req.user.id;

        // Verify and update stock for all items
        for (const item of items) {
            const stock = await ProductModel.getStock(item.product_id);

            if (stock < item.quantity) {
                await connection.rollback();
                return res.status(400).json({
                    error: `Insufficient stock for product ${item.product_id}`
                });
            }

            // Update stock
            await ProductModel.updateStock(item.product_id, item.quantity);
        }

        // Create order
        const orderId = await OrderModel.create({
            user_id: userId,
            total_amount,
            shipping_address
        });

        // Add order items
        for (const item of items) {
            await OrderModel.addOrderItem({
                order_id: orderId,
                product_id: item.product_id,
                quantity: item.quantity,
                price: item.price
            });
        }

        // Clear cart if needed
        if (req.body.clearCart) {
            await CartModel.clearCart(userId);
        }

        // Commit transaction
        await connection.commit();
        connection.release();

        res.status(201).json({
            message: 'Order created successfully',
            orderId
        });
    } catch (error) {
        // Rollback transaction on error
        await connection.rollback();
        connection.release();
        
        console.error('Order creation error:', error);
        res.status(500).json({ error: error.message });
    }
};

exports.getUserOrders = async (req, res) => {
    try {
        const userId = req.user.id;
        const orders = await OrderModel.getUserOrders(userId);
        res.json(orders);
    } catch (error) {
        console.error('Error fetching user orders:', error);
        res.status(500).json({ error: error.message });
    }
};