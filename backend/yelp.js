var request = require('request');

var YELP_HOST = 'http://api.yelp.com/v2';

var oauth = {
  consumer_key: process.env.CONSUMER_KEY,
  consumer_secret: process.env.CONSUMER_SECRET,
  token: process.env.TOKEN,
  token_secret: process.env.TOKEN_SECRET
};

function responseHandler(cb) {
  return function(err, response, body) {
    if (err) {
      return cb(err);
    }

    if (response.statusCode !== 200) {
      err = {
        name: 'YelpError',
        message: body.error.id + ' ' + body.error.text,
        status: response.statusCode
      };
      return cb(err);
    }

    cb(null, body);
  };
}

function search(query, cb) {
  request.get({
    url: YELP_HOST + '/search',
    oauth: oauth,
    qs: query,
    json: true
  }, responseHandler(cb));
}

function getBusiness(id, cb) {
  request.get({
    url: YELP_HOST + '/business/' + id,
    oauth: oauth,
    json: true
  }, responseHandler(cb));
}

module.exports = {
  search: search,
  getBusiness: getBusiness
};
