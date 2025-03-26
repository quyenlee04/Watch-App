const pool = require('../config/dbConfig');

class ProductModel {
    static async findAll() {
        const [products] = await pool.promise().query(`
            SELECT p.*, c.name as category_name 
            FROM products p 
            LEFT JOIN categories c ON p.category_id = c.id
        `);
        return products;
    }

    static async findById(id) {
        const [products] = await pool.promise().query('SELECT * FROM products WHERE id = ?', [id]);
        return products.length ? products[0] : null;
    }

    static async create(productData) {
        const { name, price, stock, brand, description, image_url, category_id } = productData;
        
        const [result] = await pool.promise().query(
            'INSERT INTO products (name, price, stock, brand, description, image_url, category_id) VALUES (?, ?, ?, ?, ?, ?, ?)',
            [name, price, stock || 0, brand, description, image_url, category_id]
        );
        
        return result.insertId;
    }

    static async update(id, productData) {
        const { name, price, stock, brand, description, image_url } = productData;
        
        const [result] = await pool.promise().query(
            'UPDATE products SET name = ?, price = ?, stock = ?, brand = ?, description = ?, image_url = COALESCE(?, image_url) WHERE id = ?',
            [name, price, stock, brand, description, image_url, id]
        );
        
        return result.affectedRows;
    }

    static async delete(id) {
        const [result] = await pool.promise().query('DELETE FROM products WHERE id = ?', [id]);
        return result.affectedRows;
    }

    static async updateStock(id, quantity) {
        const [result] = await pool.promise().query(
            'UPDATE products SET stock = stock - ? WHERE id = ?',
            [quantity, id]
        );
        return result.affectedRows;
    }

    static async getStock(id) {
        const [[result]] = await pool.promise().query('SELECT stock FROM products WHERE id = ?', [id]);
        return result ? result.stock : 0;
    }

    static async count() {
        const [[result]] = await pool.promise().query('SELECT COUNT(*) as count FROM products');
        return result.count;
    }
}

module.exports = ProductModel;