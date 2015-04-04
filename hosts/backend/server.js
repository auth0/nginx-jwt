var express = require('express');
var morgan = require('morgan');

var app = express();
app.use(morgan('combined'));

app.get('/', function (req, res) {
    res.send('Backend API root');
});

app.get('/secure', function (req, res) {
    res.json({
        message: 'This endpoint needs to be secure.'
    });
});

var server = app.listen(5000, function () {
    var host = server.address().address;
    var port = server.address().port;

    console.log('App listening at http://%s:%s', host, port);
});
