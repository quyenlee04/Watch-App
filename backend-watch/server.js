require('dotenv').config();
const express = require('express');
const cors = require('cors');
const userRoutes = require('./routes/userRoutes');
const productRoutes = require('./routes/productRoutes');
const orderRoutes = require('./routes/orderRoutes');
const cartRoutes = require('./routes/cartRoutes');
const reviewRoutes = require('./routes/reviewRoutes');
const categoryRoutes = require('./routes/categoryRoutes');
const adminRoutes = require('./routes/adminRoutes');
const bannerRoutes = require('./routes/bannerRoutes');
const pool = require("./config/dbConfig");
const path = require('path');
const session = require('express-session');
const flash = require('connect-flash');

const app = express();
const port = process.env.PORT;

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Initialize session middleware BEFORE routes
app.use(session({
  secret: process.env.SESSION_SECRET || 'watch-store-secret',
  resave: false,
  saveUninitialized: false,
  cookie: { maxAge: 24 * 60 * 60 * 1000 } // 24 hours
}));

// Initialize flash middleware
app.use(flash());

app.set('view engine', 'pug');
app.set('views', path.join(__dirname, 'views'));

// Static files
app.use(express.static(path.join(__dirname, 'public')));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

pool.getConnection(async (err) => {
  if (err) {
    console.error('Error connecting to the database:', err);
    return;
  }
  console.log('Connected to the database');
  //run file setup.sql
});

// Define routes AFTER session middleware
app.use('/api/users', userRoutes);
app.use('/api/products', productRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/cart', cartRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/banners', bannerRoutes);

// Add admin routes
app.use('/admin', adminRoutes);

app.listen(port, '0.0.0.0', () => {
  console.log(`Server is running on port ${port}`);
});

module.exports = app;