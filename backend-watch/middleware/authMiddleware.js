const jwt = require('jsonwebtoken');
const UserModel = require('../models/userModel');

exports.isAdmin = async (req, res, next) => {
    // Check if user is logged in via session
    if (!req.session.user || !req.session.token) {
        return res.redirect('/admin/login');
    }

    try {
        // Verify token
        const decoded = jwt.verify(req.session.token, process.env.JWT_SECRET);
        
        // Check if user exists and is an admin
        const user = await UserModel.findById(decoded.id);
        if (!user || user.role !== 'admin') {
            req.session.destroy();
            return res.redirect('/admin/login');
        }

        // Set user info for use in routes
        req.user = user;
        next();
    } catch (error) {
        console.error('Auth middleware error:', error);
        req.session.destroy();
        res.redirect('/admin/login');
    }
};