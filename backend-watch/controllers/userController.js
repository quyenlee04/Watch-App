const jwt = require('jsonwebtoken');
const UserModel = require('../models/userModel');
const cloudinary = require('../config/cloudinaryConfig');

exports.register = async (req, res) => {
    const { name, email, password, phone, address } = req.body;

    if (!name || !email || !password) {
        return res.status(400).json({ message: 'Please provide name, email, and password' });
    }

    try {
        // Check if email already exists
        const existingUser = await UserModel.findByEmail(email);
        if (existingUser) {
            return res.status(400).json({ message: 'Email already in use' });
        }

        const userId = await UserModel.create({
            name,
            email,
            password,
            phone,
            address
        });

        res.status(201).json({
            message: 'User registered successfully',
            userId
        });
    } catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({ message: 'Error registering user' });
    }
};

exports.login = async (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({ message: 'Email and password are required' });
    }

    try {
        // Find user by email
        const user = await UserModel.findByEmail(email);
        if (!user) {
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        // Compare passwords
        const isMatch = await UserModel.comparePassword(password, user.password);
        if (!isMatch) {
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        // Create JWT token
        const token = jwt.sign(
            {
                id: user.id,
                email: user.email,
                role: user.role,
                name: user.name
            },
            process.env.JWT_SECRET,
            { expiresIn: '24h' }
        );

        res.json({
            token,
            user: {
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role
            }
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

exports.getUserProfile = async (req, res) => {
    try {
        const userId = req.user.id;
        const user = await UserModel.findById(userId);
        
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Remove sensitive information
        const { password, ...userProfile } = user;
        res.json(userProfile);
    } catch (error) {
        console.error('Error fetching user profile:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

exports.updateUserProfile = async (req, res) => {
    try {
        const userId = req.user.id;
        const { name, email, password, phone, address } = req.body;
        let profile_picture = null;

        // Handle profile picture upload if provided
        if (req.file) {
            // Convert buffer to base64
            const b64 = Buffer.from(req.file.buffer).toString('base64');
            let dataURI = "data:" + req.file.mimetype + ";base64," + b64;

            // Upload to Cloudinary
            const uploadResponse = await cloudinary.uploader.upload(dataURI, {
                folder: 'watch_store_profiles',
            });
            profile_picture = uploadResponse.secure_url;
        }

        const affectedRows = await UserModel.update(userId, {
            name,
            email,
            password,
            phone,
            address,
            profile_picture
        });

        if (affectedRows === 0) {
            return res.status(404).json({ message: 'User not found' });
        }

        res.json({ message: 'Profile updated successfully' });
    } catch (error) {
        console.error('Error updating profile:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

