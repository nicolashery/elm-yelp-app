var express = require('express');
var bodyParser = require('body-parser');
var concurrent = require('contra').concurrent;
var yelp = require('./yelp');
var db = require('./db');

var assign = Object.assign.bind(Object);

var router = express.Router();

router.use(bodyParser.json());

function indexBy(key, arr) {
  return arr.reduce(function(acc, item) {
    acc[item[key]] = item;
    return acc;
  }, {});
}

function handleYelpError(res, err) {
  var result = {
    error: {
      name: err.name,
      message: err.message
    }
  };
  res.status(err.status || 500).send(result);
}

router.get('/v1/search', function(req, res) {
  yelp.search(req.query, function(err, data) {
    if (err) {
      return handleYelpError(res, err);
    }

    res.send(data);
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

router.get('/v1/store', function(req, res) {
  db.connect(function(err, client, done) {
    if (err) {
      return handleDbError(res, err);
    }

    concurrent({
      bookmarks: db.getBookmarks.bind(null, client),
      collections: db.getCollections.bind(null, client)
    }, function(err, data) {
      if (err) {
        return handleDbError(res, err);
      }

      var fetchYelpData = data.bookmarks.reduce(function(acc, bookmark) {
        acc[bookmark.yelp_id] = yelp.getBusiness.bind(null, bookmark.yelp_id);
        return acc;
      }, {});

      concurrent(fetchYelpData, function(err, yelpData) {
        if (err) {
          return handleYelpError(res, err);
        }

        data.bookmarks = indexBy('id', data.bookmarks);
        data.collections = indexBy('id', data.collections);
        data.yelp = yelpData;
        done();
        res.status(200).send(data);
      });
    });
  });
});

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

router.post('/v1/bookmarks', function(req, res) {
  var yelpId = req.body.yelp_id;
  var data = {
    notes: req.body.notes
  };

  db.connect(function(err, client, done) {
    if (err) {
      return handleDbError(res, err);
    }

    db.getOrCreateVenue(client, yelpId, function(err, venue) {
      if (err) {
        return handleDbError(res, err);
      }

      data = assign({}, data, {venue_id: venue.id});
      db.createBookmark(client, data, function(err, bookmark) {
        if (err) {
          return handleDbError(res, err);
        }

        done();
        res.status(201).send(bookmark);
      });
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
