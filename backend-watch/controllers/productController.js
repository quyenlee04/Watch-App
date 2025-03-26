const ProductModel = require('../models/productModel');
const cloudinary = require('../config/cloudinaryConfig');
const fs = require('fs');

exports.getAllProducts = async (req, res) => {
    try {
        const products = await ProductModel.findAll();
        res.status(200).json(products);
    } catch (error) {
        console.error('Error fetching products:', error);
        res.status(500).json({ message: error.message });
    }
};

// Add this new method for admin dashboard
exports.getAllProductsWithCategories = async () => {
    try {
        const products = await ProductModel.findAll();
        return products;
    } catch (error) {
        console.error('Error fetching products with categories:', error);
        throw error;
    }
};

exports.addProduct = async (req, res) => {
    try {
        const { name, price, stock, brand, description, category_id } = req.body;
        let image_url = null;

        if (req.file) {
            // Convert buffer to base64
            const b64 = Buffer.from(req.file.buffer).toString('base64');
            let dataURI = "data:" + req.file.mimetype + ";base64," + b64;

            // Upload to Cloudinary
            const uploadResponse = await cloudinary.uploader.upload(dataURI, {
                folder: 'watch_store_products',
            });
            image_url = uploadResponse.secure_url;
        }

        const productId = await ProductModel.create({
            name,
            price,
            stock: stock || 0,
            brand,
            description,
            image_url,
            category_id
        });

        res.status(201).json({
            message: 'Product added successfully',
            productId
        });
    } catch (error) {
        console.error('Error adding product:', error);
        res.status(500).json({ message: error.message });
    }
};

exports.getProductById = async (req, res) => {
    try {
        const product = await ProductModel.findById(req.params.id);
        
        if (!product) {
            return res.status(404).json({ message: 'Product not found' });
        }
        
        res.status(200).json(product);
    } catch (error) {
        console.error('Error fetching product:', error);
        res.status(500).json({ message: error.message });
    }
};


exports.deleteProduct = async (req, res) => {
    try {
        const affectedRows = await ProductModel.delete(req.params.id);
        
        if (affectedRows === 0) {
            return res.status(404).json({ message: 'Product not found' });
        }
        
        res.status(200).json({ message: 'Product deleted successfully' });
    } catch (error) {
        console.error('Error deleting product:', error);
        res.status(500).json({ message: error.message });
    }
};


// Update createProduct method to not send a response
exports.createProduct = async (req) => {
    try {
        const { name, price, stock, brand, category_id, description } = req.body;
        
        // Upload image if provided
        let imageUrl = '';
        if (req.file) {
            // Make sure cloudinary is properly imported at the top of the file
            const result = await cloudinary.uploader.upload(req.file.path);
            imageUrl = result.secure_url;
            
            // Delete local file after upload
            fs.unlinkSync(req.file.path);
        }
        
        // Create product in database
        await ProductModel.create({ 
            name, 
            price, 
            stock, 
            brand, 
            category_id: category_id || null, 
            description, 
            image_url: imageUrl 
        });
    } catch (error) {
        console.error('Error creating product:', error);
        throw error;
    }
};

// Update updateProduct method to not send a response
exports.updateProduct = async (req) => {
    try {
        const { id } = req.params;
        const { name, price, stock, brand, category_id, description } = req.body;
        
        // Get existing product
        const product = await ProductModel.findById(id);
        if (!product) {
            throw new Error('Product not found');
        }
        
        // Upload new image if provided
        let imageUrl = product.image_url;
        if (req.file) {
            const result = await cloudinary.uploader.upload(req.file.path);
            imageUrl = result.secure_url;
            
            // Delete local file after upload
            fs.unlinkSync(req.file.path);
        }
        
        // Update product in database
        await ProductModel.update(id, { 
            name, 
            price, 
            stock, 
            brand, 
            category_id: category_id || null, 
            description, 
            image_url: imageUrl 
        });
    } catch (error) {
        console.error('Error updating product:', error);
        throw error;
    }
};

// Update deleteProduct method to not send a response
exports.deleteProduct = async (id) => {
    try {
        // Delete product from database
        await ProductModel.delete(id);
    } catch (error) {
        console.error('Error deleting product:', error);
        throw error;
    }
};



