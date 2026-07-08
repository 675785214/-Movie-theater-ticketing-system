/*
 * @Description: 
 * @Author: Rabbiter
 * @Date: 2023-02-24 18:08:34
 */
module.exports = {
    devServer: {
        port: 9233,
        proxy: {
            '/api': {
                target: 'http://127.0.0.1:9231',
                changeOrigin: true,
                pathRewrite: { '^/api': '' }
            },
            '/images': {
                target: 'http://127.0.0.1:9231',
                changeOrigin: true
            }
        }
    },
    publicPath: process.env.NODE_ENV === 'production' ? '/admin' : '/'
}
