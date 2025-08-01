require('dotenv').config(); // Add this at the top for double safety

module.exports = function(mongoose) {
    console.log('Current working directory:', process.cwd());
    console.log('Environment variables:', Object.keys(process.env));
    
    if (!process.env.CONNECTION_URI) {
        console.error('Missing CONNECTION_URI! Check:');
        console.error('1. Is .env file in the correct location?');
        console.error('2. Does it contain CONNECTION_URI?');
        console.error('3. Are there syntax errors in .env?');
        process.exit(1);
    }
    
    mongoose.connect(process.env.CONNECTION_URI, {
        useNewUrlParser: true,
        useUnifiedTopology: true,
    })
    .then(() => console.log('✅ MongoDB Connected'))
    .catch(err => {
        console.error('❌ Connection failed:', err.message);
        console.error('URI used:', process.env.CONNECTION_URI);
    });
};