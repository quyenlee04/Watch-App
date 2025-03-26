const express = require('express');
const cartController = require('../controllers/cartController');
const { authenticate } = require('../middleware/auth'); // Assuming you have an authentication middleware
const router = express.Router();

router.get('/', authenticate, cartController.getCartItems);
router.get('/:id', authenticate, cartController.getCartItemById); // Add this line
router.post('/', authenticate, cartController.addToCart);
router.put('/', authenticate, cartController.updateCartItem);
router.delete('/', authenticate, cartController.removeCartItem);
module.exports = router;