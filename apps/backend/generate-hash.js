const bcrypt = require('bcrypt');

// Generate proper bcrypt hash for password "123456"
bcrypt.hash('123456', 10).then(hash => {
    console.log('Generated bcrypt hash for password "123456":');
    console.log(hash);
    process.exit(0);
}).catch(err => {
    console.error('Error:', err);
    process.exit(1);
});
