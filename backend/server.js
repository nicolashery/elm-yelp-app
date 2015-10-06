var express = require('express');
var cors = require('cors');
var api = require('./api');

var PORT = process.env.PORT || 8001;
var CORS_ALLOW_ORIGIN = process.env.CORS_ALLOW_ORIGIN;

var app = express();

if (CORS_ALLOW_ORIGIN) {
  console.log('Using CORS, allowing origin ' + CORS_ALLOW_ORIGIN);
  app.use(cors({
    origin: CORS_ALLOW_ORIGIN
  }));
}

app.use('/', api);

var server = app.listen(PORT, function () {
  var host = server.address().address;
  var port = server.address().port;
  console.log('Server listening at http://%s:%s', host, port);
});
