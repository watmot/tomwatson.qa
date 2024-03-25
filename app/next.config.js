const path = require('path');
const withVideos = require('next-videos');

module.exports = withVideos({
  reactStrictMode: true,
  output: 'export',
  sassOptions: {
    includePaths: [path.join(__dirname, 'src/styles')]
  },
  webpack(config) {
    config.module.rules.push({ test: /\.(woff|woff2)$/iu, type: 'asset/resource' });
    return config;
  }
});
