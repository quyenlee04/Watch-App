const UserModel = require('../models/userModel');
const ProductModel = require('../models/productModel');
const OrderModel = require('../models/orderModel');
const jwt = require('jsonwebtoken');
const cloudinary = require('../config/cloudinaryConfig');

exports.login = async (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        req.flash('error', 'Email and password are required');
        return res.redirect('/admin/login');
    }

    try {
        // Find admin by email
        const admin = await UserModel.findAdminByEmail(email);
        if (!admin) {
            req.flash('error', 'Invalid credentials or not an admin');
            return res.redirect('/admin/login');
        }

        // Compare passwords
        const isMatch = await UserModel.comparePassword(password, admin.password);
        if (!isMatch) {
            req.flash('error', 'Invalid credentials');
            return res.redirect('/admin/login');
        }

        // Create JWT token
        const token = jwt.sign(
            {
                id: admin.id,
                email: admin.email,
                role: admin.role,
                name: admin.name
            },
            process.env.JWT_SECRET,
            { expiresIn: '24h' }
        );

        // Store user info in session
        req.session.user = {
            id: admin.id,
            name: admin.name,
            email: admin.email,
            role: admin.role
        };
        req.session.token = token;

        res.redirect('/admin/dashboard');
    } catch (error) {
        console.error('Login error:', error);
        req.flash('error', 'Server error');
        res.redirect('/admin/login');
    }
};

exports.getDashboardStats = async () => {
    try {
        const productsCount = await ProductModel.count(); // Changed from getProductsCount to count
        const ordersCount = await OrderModel.getOrdersCount();
        const usersCount = await UserModel.getUsersCount();

        return {
            products: productsCount,
            orders: ordersCount,
            users: usersCount
        };
    } catch (error) {
        console.error('Error getting dashboard stats:', error);
        throw error;
    }
};

exports.getRecentOrders = async (limit = 5) => {
    try {
        return await OrderModel.getRecentOrders(limit);
    } catch (error) {
        console.error('Error getting recent orders:', error);
        throw error;
    }
};

exports.getOrders = async () => {
    try {
        // Change from getAllOrdersWithUserInfo to getAllOrders
        return await OrderModel.getAllOrders();
    } catch (error) {
        console.error('Error getting orders:', error);
        throw error;
    }
};

exports.getOrderDetails = async (orderId) => {
    try {
        const order = await OrderModel.getOrderById(orderId);
        if (!order) {
            throw new Error('Order not found');
        }
        
        const items = await OrderModel.getOrderItems(orderId);
        return { ...order, items };
    } catch (error) {
        console.error('Error getting order details:', error);
        throw error;
    }
};

// Update the updateOrderStatus method to use the correct method name
exports.updateOrderStatus = async (orderId, status) => {
    try {
        // Change from OrderModel.updateOrderStatus to OrderModel.updateStatus
        const result = await OrderModel.updateStatus(orderId, status);
        
        if (result === 0) {
            throw new Error('Order not found');
        }
        
        return result;
    } catch (error) {
        console.error('Error updating order status:', error);
        throw error;
    }
};

exports.getUsers = async () => {
    try {
        return await UserModel.getAllUsers();
    } catch (error) {
        console.error('Error getting users:', error);
        throw error;
    }
};

exports.addUser = async (req, res) => {
    const { name, email, password, phone, address } = req.body;

    if (!name || !email || !password) {
        throw new Error('Name, email, and password are required');
    }

    try {
        // Check if email already exists
        const existingUser = await UserModel.findByEmail(email);
        if (existingUser) {
            throw new Error('Email already in use');
        }

        await UserModel.create({
            name,
            email,
            password,
            phone,
            address
        });
    } catch (error) {
        console.error('Error adding user:', error);
        throw error;
    }
};

exports.updateUser = async (userId, userData) => {
    try {
        const result = await UserModel.update(userId, userData);
        if (result === 0) {
            throw new Error('User not found');
        }
        return result;
    } catch (error) {
        console.error('Error updating user:', error);
        throw error;
    }
};

exports.deleteUser = async (userId) => {
    try {
        const result = await UserModel.delete(userId);
        if (result === 0) {
            throw new Error('User not found');
        }
        return result;
    } catch (error) {
        console.error('Error deleting user:', error);
        throw error;
    }
};

exports.getUserById = async (userId) => {
  try {
    return await UserModel.findById(userId);
  } catch (error) {
    console.error('Error getting user by ID:', error);
    throw error;
  }
};

exports.updateProfile = async (userId, req) => {
  try {
    const { name, email, phone, password, confirm_password } = req.body;
    
    // Validate password if provided
    if (password) {
      if (password !== confirm_password) {
        throw new Error('Passwords do not match');
      }
      if (password.length < 6) {
        throw new Error('Password must be at least 6 characters');
      }
    }
    
    // Handle profile picture upload
    let profile_picture = undefined;
    if (req.file) {
      // Upload to cloudinary if configured
      const result = await cloudinary.uploader.upload(req.file.path);
      profile_picture = result.secure_url;
    }
    
    // Update user profile
    await UserModel.update(userId, {
      name,
      email,
      phone,
      password: password || undefined,
      profile_picture
    });
    
    return true;
  } catch (error) {
    console.error('Error updating profile:', error);
    throw error;
  }
};
