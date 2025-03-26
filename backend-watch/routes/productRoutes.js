const express = require('express');
const productController = require('../controllers/productController');
const multer = require('multer');
const { authenticate } = require('../middleware/auth');

// Configure multer for memory storage instead of disk storage
const storage = multer.memoryStorage();
const upload = multer({ storage: storage });

const router = express.Router();

router.get('/', productController.getAllProducts);
router.post('/create', authenticate, upload.single('image'), productController.addProduct);
router.get('/:id', productController.getProductById);
router.put('/:id', authenticate, upload.single('image'), productController.updateProduct);
router.delete('/:id', authenticate, productController.deleteProduct);

module.exports = router;