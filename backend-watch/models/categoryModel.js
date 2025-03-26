const pool = require('../config/dbConfig');

class CategoryModel {
    static async getAll() {
        const [categories] = await pool.promise().query('SELECT id, name, description FROM categories');
        return categories;
    }

    static async create(categoryData) {
        const { name, description } = categoryData;
        
        const [result] = await pool.promise().query(
            'INSERT INTO categories (name, description) VALUES (?, ?)',
            [name, description]
        );
        
        return result.insertId;
    }

    static async delete(id) {
        const [result] = await pool.promise().query('DELETE FROM categories WHERE id = ?', [id]);
        return result.affectedRows;
    }
}

module.exports = CategoryModel;