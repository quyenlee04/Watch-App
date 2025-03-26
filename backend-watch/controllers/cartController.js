const CartModel = require('../models/cartModel');
const ProductModel = require('../models/productModel');

exports.getCartItems = async (req, res) => {
    try {
        const userId = req.user.id;
        const items = await CartModel.getCartItems(userId);
        res.status(200).json(items);
    } catch (error) {
        console.error('Error fetching cart items:', error);
        res.status(500).json({ message: error.message });
    }
};

exports.getCartItemById = async (req, res) => {
    try {
        const userId = req.user.id;
        const cartId = req.params.id;
        const item = await CartModel.getCartItemById(cartId, userId);
        
        if (!item) {
            return res.status(404).json({ message: 'Cart item not found' });
        }
        
        res.status(200).json(item);
    } catch (error) {
        console.error('Error fetching cart item:', error);
        res.status(500).json({ message: error.message });
    }
};

exports.addToCart = async (req, res) => {
    try {
        const { product_id, quantity } = req.body;
        const userId = req.user.id;
        
        console.log('🛒 User making request:', req.user);
        
        if (!req.user) {
            return res.status(401).json({ message: 'Unauthorized - No user info' });
        }

        const cartId = await CartModel.addToCart({
            user_id: userId,
            product_id,
            quantity
        });

        res.status(201).json({ 
            message: 'Item added to cart',
            cartId
        });
    } catch (error) {
        console.error('Error adding to cart:', error);
        res.status(500).json({ message: error.message });
    }
};

exports.updateCartItem = async (req, res) => {
    try {
        const { cart_id, quantity } = req.body;
        
        const affectedRows = await CartModel.updateCartItem(cart_id, quantity);
        
        if (affectedRows === 0) {
            return res.status(404).json({ message: 'Cart item not found' });
        }
        
        res.status(200).json({ message: 'Cart updated' });
    } catch (error) {
        console.error('Error updating cart:', error);
        res.status(500).json({ message: error.message });
    }
};

exports.removeCartItem = async (req, res) => {
    try {
        const { cart_id } = req.body;
        
        const affectedRows = await CartModel.removeCartItem(cart_id);
        
        if (affectedRows === 0) {
            return res.status(404).json({ message: 'Cart item not found' });
        }
        
        res.status(200).json({ message: 'Item removed from cart' });
    } catch (error) {
        console.error('Error removing from cart:', error);
        res.status(500).json({ message: error.message });
    }
};