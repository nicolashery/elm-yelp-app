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

function handleDbError(res, err) {
  var status = err.severity === 'FATAL' ? 500 : 400;
  var result = {
    error: {
      name: 'DbError',
      message: err.message
    }
  };
  res.status(status).send(result);
}

router.post('/v1/collections', function(req, res) {
  var data = {
    name: req.body.name,
    description: req.body.description
  };

  db.connect(function(err, client, done) {
    if (err) {
      return handleDbError(res, err);
    }

    db.createCollection(client, data, function(err, collection) {
      if (err) {
        return handleDbError(res, err);
      }

      done();
      res.status(201).send(collection);
    });
  });
});

router.get('/v1/collections', function(req, res) {
  db.connect(function(err, client, done) {
    if (err) {
      return handleDbError(res, err);
    }

    db.getCollections(client, function(err, collections) {
      if (err) {
        return handleDbError(res, err);
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
      return handleDbError(res, err);
    }

    db.getCollection(client, id, function(err, collection) {
      if (err) {
        return handleDbError(res, err);
      }

      done();
      if (!collection) {
        return handleNotFound(res);
      }

      res.send(collection);
    });
  });
});

router.put('/v1/collections/:id', function(req, res) {
  var id = req.params.id;
  var data = {
    name: req.body.name,
    description: req.body.description
  };

  db.connect(function(err, client, done) {
    if (err) {
      return handleDbError(res, err);
    }

    db.updateCollection(client, id, data, function(err, collection) {
      if (err) {
        return handleDbError(res, err);
      }

      done();
      if (!collection) {
        return handleNotFound(res);
      }

      res.send(collection);
    });
  });
});

router.delete('/v1/collections/:id', function(req, res) {
  var id = req.params.id;

  db.connect(function(err, client, done) {
    if (err) {
      return handleDbError(res, err);
    }

    db.deleteCollection(client, id, function(err) {
      if (err) {
        return handleDbError(res, err);
      }

      done();
      res.send();
    });
  });
});

router.post('/v1/venues', function(req, res) {
  var data = {
    yelp_id: req.body.yelp_id
  };

  db.connect(function(err, client, done) {
    if (err) {
      return handleDbError(res, err);
    }

    db.createVenue(client, data, function(err, venue) {
      if (err) {
        return handleDbError(res, err);
      }

      done();
      res.status(201).send(venue);
    });
  });
});

router.post('/v1/bookmarks', function(req, res) {
  var data = {
    venue_id: req.body.venue_id,
    notes: req.body.notes
  };

  db.connect(function(err, client, done) {
    if (err) {
      return handleDbError(res, err);
    }

    db.createBookmark(client, data, function(err, bookmark) {
      if (err) {
        return handleDbError(res, err);
      }

      done();
      res.status(201).send(bookmark);
    });
  });
});

router.put('/v1/bookmarks/:id', function(req, res) {
  var id = req.params.id;
  var data = {
    notes: req.body.notes
  };

  db.connect(function(err, client, done) {
    if (err) {
      return handleDbError(res, err);
    }

    db.updateBookmark(client, id, data, function(err, bookmark) {
      if (err) {
        return handleDbError(res, err);
      }

      done();
      res.status(201).send(bookmark);
    });
  });
});

router.post('/v1/bookmarks/:id/collections', function(req, res) {
  var bookmarkId = req.params.id;
  var collectionId = req.body.id;

  db.connect(function(err, client, done) {
    if (err) {
      return handleDbError(res, err);
    }

    db.addBookmarkToCollection(client, bookmarkId, collectionId, function(err) {
      if (err) {
        return handleDbError(res, err);
      }

      done();
      res.status(201).send();
    });
  });
});

router.delete('/v1/bookmarks/:id/collections/:collectionId', function(req, res) {
  var bookmarkId = req.params.id;
  var collectionId = req.params.collectionId;

  db.connect(function(err, client, done) {
    if (err) {
      return handleDbError(res, err);
    }

    db.removeBookmarkFromCollection(client, bookmarkId, collectionId, function(err) {
      if (err) {
        return handleDbError(res, err);
      }

      done();
      res.send();
    });
  });
});

module.exports = router;
