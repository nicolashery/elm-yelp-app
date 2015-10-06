var express = require('express');
var bodyParser = require('body-parser');
var yelp = require('./yelp');
var db = require('./db');

var router = express.Router();

router.use(bodyParser.json());

function handleYelpError(res, body, status) {
  var result = {
    error: {
      name: 'YelpError',
      message: body.error.id + ' ' + body.error.text
    }
  };
  res.status(status).send(result);
}

router.get('/v1/search', function(req, res, next) {
  yelp.search(req.query, function(err, response, body) {
    if (err) {
      return next(err);
    }

    if (response.statusCode !== 200) {
      return handleYelpError(res, body, response.statusCode);
    }

    res.send(body);
  });
});

function handlePgError(res, err, status) {
  status = status || 400;
  var result = {
    error: {
      name: 'PgError',
      message: err.message
    }
  };
  res.status(status).send(result);
}

router.post('/v1/collections', function(req, res) {
  var name = req.body.name;
  var description = req.body.description;

  db.connect(function(err, client, done) {
    if (err) {
      return handlePgError(res, err, 500);
    }

    db.createCollection(client, name, description, function(err, collection) {
      if (err) {
        return handlePgError(res, err);
      }

      done();
      res.status(201).send(collection);
    });
  });
});

router.get('/v1/collections', function(req, res) {
  db.connect(function(err, client, done) {
    if (err) {
      return handlePgError(res, err, 500);
    }

    db.getCollections(client, function(err, collections) {
      if (err) {
        return handlePgError(res, err);
      }

      done();
      res.send(collections);
    });
  });
});

function handleNotFound(res) {
  var result = {
    error: {
      name: 'NotFound',
      message: 'Could not find resource'
    }
  };
  res.status(404).send(result);
}

router.get('/v1/collections/:id', function(req, res) {
  var id = req.params.id;

  db.connect(function(err, client, done) {
    if (err) {
      return handlePgError(res, err, 500);
    }

    db.getCollection(client, id, function(err, collection) {
      if (err) {
        return handlePgError(res, err);
      }

      done();
      if (!collection) {
        return handleNotFound(res);
      }

      res.send(collection);
    });
  });
});

module.exports = router;
