const jwt = require('jsonwebtoken');

exports.authenticate = (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ message: 'Unauthorized - No token provided' });
        }

        const token = authHeader.split(' ')[1];
        jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
            if (err) {
                console.error('Token verification failed:', err.message);
                return res.status(401).json({ message: 'Unauthorized - Invalid token' });
            }

            console.log('Token verified:', decoded);
            req.user = decoded;
            next();
        });
    } catch (error) {
        console.error('Authentication error:', error);
        return res.status(500).json({ message: 'Internal Server Error' });
    }
};

exports.isAdmin = (req, res, next) => {
    if (req.user && req.user.role === 'admin') {
        next();
    } else {
        res.status(403).json({ message: 'Access denied. Admin only.' });
    }
};
