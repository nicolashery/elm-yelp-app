var express = require('express');
var cors = require('cors');
var yelp = require('./yelp');

var PORT = process.env.PORT || 8001;
var CORS_ALLOW_ORIGIN = process.env.CORS_ALLOW_ORIGIN;

var app = express();

if (CORS_ALLOW_ORIGIN) {
  console.log('Using CORS, allowing origin ' + CORS_ALLOW_ORIGIN);
  app.use(cors({
    origin: CORS_ALLOW_ORIGIN
  }));
}

app.get('/search', function(req, res, next) {
  yelp.search(req.query, function(err, response, body) {
    if (err) {
      return next(err)
    };

    res.status(response.statusCode).send(body);
  });
});

var server = app.listen(PORT, function () {
  var host = server.address().address;
  var port = server.address().port;
  console.log('Server listening at http://%s:%s', host, port);
});
