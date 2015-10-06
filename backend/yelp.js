var request = require('request');

var API_HOST = 'http://api.yelp.com/v2';

var oauth = {
  consumer_key: process.env.CONSUMER_KEY,
  consumer_secret: process.env.CONSUMER_SECRET,
  token: process.env.TOKEN,
  token_secret: process.env.TOKEN_SECRET
};

function search(query, cb) {
  request.get({
    url: API_HOST + '/search',
    oauth: oauth,
    qs: query,
    json: true
  }, cb);
}

module.exports = {
  search: search
};
