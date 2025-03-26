const BannerModel = require('../models/bannerModel');
const cloudinary = require('../config/cloudinaryConfig');
const fs = require('fs');

exports.createBanner = async (req) => {
    try {
        const { title, link } = req.body;
        
        // Upload image to Cloudinary
        let imageUrl = '';
        if (req.file) {
            const result = await cloudinary.uploader.upload(req.file.path);
            imageUrl = result.secure_url;
            
            // Delete local file after upload
            fs.unlinkSync(req.file.path);
        }
        
        // Create banner in database
        await BannerModel.create({ title, link, imageUrl });
    } catch (error) {
        console.error('Error creating banner:', error);
        throw error;
    }
};

exports.getBanners = async (req, res) => {
    try {
        const banners = await BannerModel.getAll();
        res.json(banners);
    } catch (error) {
        console.error('Error fetching banners:', error);
        res.status(500).json({ message: 'Error fetching banners' });
    }
};

// Add this new method for admin routes
exports.getAllBanners = async () => {
    try {
        return await BannerModel.getAll();
    } catch (error) {
        console.error('Error fetching banners:', error);
        throw error;
    }
};

exports.deleteBanner = async (req) => {
    try {
        const { id } = req.params;
        
        // Delete banner from database
        await BannerModel.delete(id);
    } catch (error) {
        console.error('Error deleting banner:', error);
        throw error;
    }
};

exports.updateBanner = async (req) => {
    try {
        const { id } = req.params;
        const { title, link } = req.body;
        
        // Get existing banner
        const banner = await BannerModel.getById(id);
        if (!banner) {
            throw new Error('Banner not found');
        }
        
        // Upload new image if provided
        let imageUrl = banner.imageUrl;
        if (req.file) {
            const result = await cloudinary.uploader.upload(req.file.path);
            imageUrl = result.secure_url;
            
            // Delete local file after upload
            fs.unlinkSync(req.file.path);
        }
        
        // Update banner in database
        await BannerModel.update(id, { title, link, imageUrl });
    } catch (error) {
        console.error('Error updating banner:', error);
        throw error;
    }
};
