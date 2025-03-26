const express = require('express');
const userController = require('../controllers/userController');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const multer = require('multer');

// Configure multer for memory storage
const storage = multer.memoryStorage();
const upload = multer({ storage: storage });

router.post('/register', userController.register);
router.post('/login', userController.login);
router.get('/profile', authenticate, userController.getUserProfile);
router.put('/profile', authenticate, upload.single('profile_picture'), userController.updateUserProfile);

module.exports = router;