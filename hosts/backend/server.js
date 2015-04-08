var express = require('express');
var morgan = require('morgan');

var app = express();
app.use(morgan('combined'));

app.get('/', function (req, res) {
    res.send('Backend API root');
});

app.get('/secure', function (req, res) {
    console.log('Authorization header:', req.get('Authorization'));

    res.json({
        message: 'This endpoint needs to be secure.'
    });
});

app.get('/secure/admin', function (req, res) {
    console.log('Authorization header:', req.get('Authorization'));

    res.json({
        message: 'This endpoint needs to be secure for an admin.'
    });
});

var server = app.listen(5000, function () {
    var host = server.address().address;
    var port = server.address().port;

    console.log('App listening at http://%s:%s', host, port);
});
