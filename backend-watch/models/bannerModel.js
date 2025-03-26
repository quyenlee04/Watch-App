const pool = require('../config/dbConfig');

class BannerModel {
    static async create(bannerData) {
        const { imageUrl, title, link } = bannerData;
        
        const [result] = await pool.promise().query(
            'INSERT INTO banners (imageUrl, title, link) VALUES (?, ?, ?)',
            [imageUrl, title, link]
        );
        
        return result.insertId;
    }

    static async getAll() {
        const [banners] = await pool.promise().query('SELECT * FROM banners');
        return banners;
    }

    static async delete(id) {
        const [result] = await pool.promise().query('DELETE FROM banners WHERE id = ?', [id]);
        return result.affectedRows;
    }

    static async update(id, bannerData) {
        const { title, link } = bannerData;
        
        const [result] = await pool.promise().query(
            'UPDATE banners SET title = ?, link = ? WHERE id = ?',
            [title, link, id]
        );
        
        return result.affectedRows;
    }
}

module.exports = BannerModel;