const CategoryModel = require('../models/categoryModel');

// Add a new category
exports.addCategory = async (req, res) => {
    try {
        const { name, description } = req.body;

        if (!name) {
            return res.status(400).json({ message: 'Please provide a category name' });
        }

        const categoryId = await CategoryModel.create({ name, description });
        
        res.status(201).json({ 
            message: 'Category added successfully', 
            categoryId 
        });
    } catch (error) {
        console.error('Error adding category:', error);
        res.status(500).json({ message: error.message });
    }
};

// HTTP endpoint for getting categories
exports.getAllCategories = async (req, res) => {
    try {
        const categories = await CategoryModel.getAll();
        res.status(200).json(categories);
    } catch (error) {
        console.error('Error fetching categories:', error);
        res.status(500).json({ message: error.message });
    }
};

// New method for internal use (no req/res)
exports.getCategories = async () => {
    try {
        const categories = await CategoryModel.getAll();
        return categories;
    } catch (error) {
        console.error('Error fetching categories:', error);
        throw error;
    }
};

exports.deleteCategory = async (req, res) => {
    try {
        const affectedRows = await CategoryModel.delete(req.params.id);
        
        if (affectedRows === 0) {
            return res.status(404).json({ message: 'Category not found' });
        }
        
        res.status(204).send();
    } catch (error) {
        console.error('Error deleting category:', error);
        res.status(500).json({ message: error.message });
    }
};

// Update the addCategory method to not send a response
exports.addCategory = async (req) => {
    try {
        const { name } = req.body;
        
        // Create category in database
        await CategoryModel.create({ name });
    } catch (error) {
        console.error('Error creating category:', error);
        throw error;
    }
};

// Update the updateCategory method to not send a response
exports.updateCategory = async (req) => {
    try {
        const { id } = req.params;
        const { name } = req.body;
        
        // Update category in database
        await CategoryModel.update(id, { name });
    } catch (error) {
        console.error('Error updating category:', error);
        throw error;
    }
};

// Update the deleteCategory method to not send a response
exports.deleteCategory = async (id) => {
    try {
        // Delete category from database
        await CategoryModel.delete(id);
    } catch (error) {
        console.error('Error deleting category:', error);
        throw error;
    }
};