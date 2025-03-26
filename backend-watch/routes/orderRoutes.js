const express = require('express');
const orderController = require('../controllers/orderController');
const { authenticate } = require('../middleware/auth'); // Assuming you have an authentication middleware
const router = express.Router();

router.post('/', authenticate, orderController.createOrder);
router.get('/', authenticate, orderController.getUserOrders);

module.exports = router;