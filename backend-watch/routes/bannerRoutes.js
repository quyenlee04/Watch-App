const express = require('express');
const router = express.Router();
const multer = require('multer');
const upload = multer({ dest: 'uploads/' });
const { createBanner, getBanners, deleteBanner, updateBanner } = require('../controllers/bannerController');

router.post('/', upload.single('image'), createBanner);
router.get('/', getBanners);
router.delete('/:id', deleteBanner);
router.put('/:id', updateBanner);

module.exports = router;
