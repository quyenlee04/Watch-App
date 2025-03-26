const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const productController = require('../controllers/productController');
const categoryController = require('../controllers/categoryController');
const orderController = require('../controllers/orderController');
const bannerController = require('../controllers/bannerController');
const multer = require('multer');
const path = require('path');
const { isAdmin } = require('../middleware/authMiddleware');

// Configure multer for file uploads
const storage = multer.diskStorage({
    destination: function(req, file, cb) {
        cb(null, 'uploads/');
    },
    filename: function(req, file, cb) {
        cb(null, Date.now() + path.extname(file.originalname));
    }
});

const upload = multer({ storage: storage });

// Admin login routes (no auth required)
router.get('/login', (req, res) => {
    res.render('admin/login', { error: req.flash('error') });
});

router.post('/login', adminController.login);

router.get('/logout', (req, res) => {
    req.session.destroy();
    res.redirect('/admin/login');
});

// All routes below this middleware require admin authentication
router.use(isAdmin);

// Dashboard
router.get('/dashboard', async (req, res) => {
    try {
        const stats = await adminController.getDashboardStats();
        const recentOrders = await adminController.getRecentOrders(5);
        
        res.render('admin/dashboard', {
            currentPage: 'dashboard',
            user: req.user,
            stats,
            recentOrders
        });
    } catch (error) {
        console.error('Dashboard error:', error);
        res.render('admin/dashboard', {
            currentPage: 'dashboard',
            user: req.user,
            error: 'Error loading dashboard data',
            stats: { products: 0, orders: 0, users: 0 },
            recentOrders: []
        });
    }
});

// Find the product routes section and update it:

// Products
router.get('/products', async (req, res) => {
    try {
        const products = await productController.getAllProductsWithCategories();
        const categories = await categoryController.getCategories();
        
        res.render('admin/products', {
            currentPage: 'products',
            user: req.user,
            products,
            categories,
            success: req.flash('success'),
            error: req.flash('error')
        });
    } catch (error) {
        console.error('Products page error:', error);
        req.flash('error', 'Error loading products');
        res.redirect('/admin/dashboard');
    }
});

router.post('/products', upload.single('image'), async (req, res) => {
    try {
        // Modified to not send response directly from controller
        await productController.createProduct(req);
        req.flash('success', 'Product added successfully');
        res.redirect('/admin/products');
    } catch (error) {
        req.flash('error', error.message || 'Error adding product');
        res.redirect('/admin/products');
    }
});

router.post('/products/:id', upload.single('image'), async (req, res) => {
    try {
        if (req.body._method === 'PUT') {
            // Modified to not send response directly from controller
            await productController.updateProduct(req);
            req.flash('success', 'Product updated successfully');
        } else if (req.body._method === 'DELETE') {
            // Modified to not send response directly from controller
            await productController.deleteProduct(req.params.id);
            req.flash('success', 'Product deleted successfully');
        }
        res.redirect('/admin/products');
    } catch (error) {
        req.flash('error', error.message || 'Error processing request');
        res.redirect('/admin/products');
    }
});

// Categories
router.get('/categories', async (req, res) => {
    try {
        // Use the new getCategories method here too
        const categories = await categoryController.getCategories();
        
        res.render('admin/categories', {
            currentPage: 'categories',
            user: req.user,
            categories,
            success: req.flash('success'),
            error: req.flash('error')
        });
    } catch (error) {
        console.error('Categories page error:', error);
        req.flash('error', 'Error loading categories');
        res.redirect('/admin/dashboard');
    }
});

router.post('/categories', async (req, res) => {
    try {
        // Modified to not send response directly from controller
        await categoryController.addCategory(req);
        req.flash('success', 'Category added successfully');
    } catch (error) {
        req.flash('error', error.message || 'Error adding category');
    }
    res.redirect('/admin/categories');
});

router.post('/categories/:id', async (req, res) => {
    try {
        if (req.body._method === 'PUT') {
            // Modified to not send response directly from controller
            await categoryController.updateCategory(req);
            req.flash('success', 'Category updated successfully');
        } else if (req.body._method === 'DELETE') {
            // Modified to not send response directly from controller
            await categoryController.deleteCategory(req.params.id);
            req.flash('success', 'Category deleted successfully');
        }
    } catch (error) {
        req.flash('error', error.message || 'Error processing request');
    }
    res.redirect('/admin/categories');
});

// Orders
router.get('/orders', async (req, res) => {
    try {
        const orders = await adminController.getOrders();
        
        res.render('admin/orders', {
            currentPage: 'orders',
            user: req.user,
            orders,
            success: req.flash('success'),
            error: req.flash('error')
        });
    } catch (error) {
        console.error('Orders page error:', error);
        req.flash('error', 'Error loading orders');
        res.redirect('/admin/dashboard');
    }
});

router.get('/orders/:id', async (req, res) => {
    try {
        const orderDetails = await adminController.getOrderDetails(req.params.id);
        
        res.render('admin/order-details', {
            currentPage: 'orders',
            user: req.user,
            order: orderDetails,
            items: orderDetails.items,
            success: req.flash('success'),
            error: req.flash('error')
        });
    } catch (error) {
        console.error('Order details error:', error);
        req.flash('error', 'Error loading order details');
        res.redirect('/admin/orders');
    }
});

router.post('/orders/:id/status', async (req, res) => {
    try {
        await adminController.updateOrderStatus(req.params.id, req.body.status);
        req.flash('success', 'Order status updated successfully');
    } catch (error) {
        req.flash('error', error.message || 'Error updating order status');
    }
    res.redirect(`/admin/orders/${req.params.id}`);
});

// Users
router.get('/users', async (req, res) => {
    try {
        const users = await adminController.getUsers();
        
        res.render('admin/users', {
            currentPage: 'users',
            user: req.user,
            users,
            success: req.flash('success'),
            error: req.flash('error')
        });
    } catch (error) {
        console.error('Users page error:', error);
        req.flash('error', 'Error loading users');
        res.redirect('/admin/dashboard');
    }
});

router.post('/users', async (req, res) => {
    try {
        await adminController.addUser(req, res);
        req.flash('success', 'User added successfully');
    } catch (error) {
        req.flash('error', error.message || 'Error adding user');
    }
    res.redirect('/admin/users');
});

router.post('/users/:id', async (req, res) => {
    try {
        if (req.body._method === 'PUT') {
            await adminController.updateUser(req.params.id, req.body);
            req.flash('success', 'User updated successfully');
        } else if (req.body._method === 'DELETE') {
            await adminController.deleteUser(req.params.id);
            req.flash('success', 'User deleted successfully');
        }
    } catch (error) {
        req.flash('error', error.message || 'Error processing request');
    }
    res.redirect('/admin/users');
});

// Banners
router.get('/banners', async (req, res) => {
    try {
        const banners = await bannerController.getAllBanners();
        
        res.render('admin/banners', {
            currentPage: 'banners',
            user: req.user,
            banners,
            success: req.flash('success'),
            error: req.flash('error')
        });
    } catch (error) {
        console.error('Banners page error:', error);
        req.flash('error', 'Error loading banners');
        res.redirect('/admin/dashboard');
    }
});

router.post('/banners', upload.single('image'), async (req, res) => {
    try {
        // Modified to not send response directly from controller
        await bannerController.createBanner(req);
        req.flash('success', 'Banner added successfully');
        res.redirect('/admin/banners');
    } catch (error) {
        req.flash('error', error.message || 'Error adding banner');
        res.redirect('/admin/banners');
    }
});

router.post('/banners/:id', upload.single('image'), async (req, res) => {
    try {
        if (req.body._method === 'PUT') {
            // Modified to not send response directly from controller
            await bannerController.updateBanner(req);
            req.flash('success', 'Banner updated successfully');
        } else if (req.body._method === 'DELETE') {
            // Modified to not send response directly from controller
            await bannerController.deleteBanner(req);
            req.flash('success', 'Banner deleted successfully');
        }
        res.redirect('/admin/banners');
    } catch (error) {
        req.flash('error', error.message || 'Error processing request');
        res.redirect('/admin/banners');
    }
});

// Profile
router.get('/profile', (req, res) => {
    res.render('admin/profile', {
        currentPage: '',
        user: req.user,
        success: req.flash('success'),
        error: req.flash('error')
    });
});

router.post('/profile', upload.single('profile_picture'), async (req, res) => {
    try {
        await adminController.updateProfile(req);
        req.flash('success', 'Profile updated successfully');
    } catch (error) {
        req.flash('error', error.message || 'Error updating profile');
    }
    res.redirect('/admin/profile');
});

module.exports = router;
