const express = require('express');

const app = express();
const port = process.env.PORT || 3011;

const corsOrigin = process.env.CORS_ORIGIN || '*';
app.use((req, res, next) => {
    res.setHeader('Access-Control-Allow-Origin', corsOrigin);
    res.setHeader('Access-Control-Allow-Methods', 'GET');
    next();
});

app.get('/', (req, res) => {
    res.send('Demo Server');
});

app.get('/health', (req, res) => {
    res.status(200).json({
        service: 'rewards',
        status: 'ok',
        commit: '',
        region: ''
    });
});

app.listen(port, () => {
    console.log(`Server listening on port ${port}`);
});