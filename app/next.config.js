const path = require('path');
const withVideos = require('next-videos');

module.exports = withVideos({
  reactStrictMode: true,
  output: 'export',
  sassOptions: {
    includePaths: [path.join(__dirname, 'src/styles')]
  }
});
