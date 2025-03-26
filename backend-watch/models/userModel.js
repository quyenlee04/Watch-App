const pool = require('../config/dbConfig');
const bcrypt = require('bcrypt');

class UserModel {
    static async findByEmail(email) {
        const [users] = await pool.promise().query('SELECT * FROM users WHERE email = ?', [email]);
        return users.length ? users[0] : null;
    }

    static async findById(id) {
        const [users] = await pool.promise().query('SELECT * FROM users WHERE id = ?', [id]);
        return users.length ? users[0] : null;
    }

    static async findAdminByEmail(email) {
        const [users] = await pool.promise().query(
            'SELECT * FROM users WHERE email = ? AND role = ?',
            [email, 'admin']
        );
        return users.length ? users[0] : null;
    }

    static async create(userData) {
        const { name, email, password, phone, address, role = 'user' } = userData;
        const hashedPassword = await bcrypt.hash(password, 10);
        const created_at = new Date().toISOString().slice(0, 19).replace('T', ' ');

        const [result] = await pool.promise().query(
            'INSERT INTO users (name, email, password, phone, address, role, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
            [name, email, hashedPassword, phone || null, address || null, role, created_at]
        );

        return result.insertId;
    }

    static async update(id, userData) {
        const { name, email, password, phone, address, profile_picture } = userData;
        
        if (password) {
            const hashedPassword = await bcrypt.hash(password, 10);
            const [result] = await pool.promise().query(
                'UPDATE users SET name = ?, email = ?, password = ?, phone = ?, address = ?, profile_picture = COALESCE(?, profile_picture) WHERE id = ?',
                [name, email, hashedPassword, phone, address, profile_picture, id]
            );
            return result.affectedRows;
        } else {
            const [result] = await pool.promise().query(
                'UPDATE users SET name = ?, email = ?, phone = ?, address = ?, profile_picture = COALESCE(?, profile_picture) WHERE id = ?',
                [name, email, phone, address, profile_picture, id]
            );
            return result.affectedRows;
        }
    }

    static async delete(id) {
        const [result] = await pool.promise().query('DELETE FROM users WHERE id = ?', [id]);
        return result.affectedRows;
    }

    static async getAllUsers() {
        const [users] = await pool.promise().query(
            'SELECT id, name, email, address, phone, profile_picture, role, created_at FROM users WHERE role != "admin"'
        );
        return users;
    }

    static async comparePassword(plainPassword, hashedPassword) {
        return bcrypt.compare(plainPassword, hashedPassword);
    }

    // Add this method to your UserModel class
    static async getUsersCount() {
        const [[result]] = await pool.promise().query('SELECT COUNT(*) as count FROM users');
        return result.count;
    }
}

module.exports = UserModel;