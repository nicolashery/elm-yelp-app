var pg = require('pg');
var types = require('pg').types;

var DATABASE_URL = process.env.DATABASE_URL || 'postgres://localhost:5432/elm-yelp-app';

// Override pg's timestamp parsing logic to force parsing as UTC
var TIMESTAMP_OID = 1114;
function parseTimestamp(value) {
  if (!value) {
    return value;
  }
  value = value.replace(' ', 'T') + 'Z';
  return new Date(value);
}
types.setTypeParser(TIMESTAMP_OID, parseTimestamp);

function connect(cb) {
  pg.connect(DATABASE_URL, cb);
}

function createCollection(client, data, cb) {
  client.query('INSERT INTO collections(name, description) values($1, $2) RETURNING *', [
    data.name, data.description
  ], function(err, result) {
    if (err) {
      return cb(err);
    }

    cb(null, result.rows[0]);
  });
}

function getCollections(client, cb) {
  client.query('SELECT * FROM collections ORDER BY updated_at DESC', function(err, result) {
    if (err) {
      return cb(err);
    }

    cb(null, result.rows);
  });
}

function getCollection(client, id, cb) {
  client.query('SELECT * FROM collections WHERE id=($1)', [id], function(err, result) {
    if (err) {
      return cb(err);
    }

    cb(null, result.rows[0]);
  });
}

function updateCollection(client, id, data, cb) {
  client.query('UPDATE collections SET name=($1), description=($2) WHERE id=($3) RETURNING *', [
    data.name, data.description, id
  ], function(err, result) {
    if (err) {
      return cb(err);
    }

    cb(null, result.rows[0]);
  });
}

function deleteCollection(client, id, cb) {
  client.query('DELETE FROM collections WHERE id=($1)', [id], function(err) {
    if (err) {
      return cb(err);
    }

    cb(null);
  });
}

function createVenue(client, data, cb) {
  client.query('INSERT INTO venues(yelp_id) values($1) RETURNING *', [
    data.yelp_id
  ], function(err, result) {
    if (err) {
      return cb(err);
    }

    cb(null, result.rows[0]);
  });
}

function createBookmark(client, data, cb) {
  client.query('INSERT INTO bookmarks(venue_id, notes) values($1, $2) RETURNING *', [
    data.venue_id, data.notes
  ], function(err, result) {
    if (err) {
      return cb(err);
    }

    cb(null, result.rows[0]);
  });
}

function updateBookmark(client, id, data, cb) {
  client.query('UPDATE bookmarks SET notes=($1) WHERE id=($2) RETURNING *', [
    data.notes, id
  ], function(err, result) {
    if (err) {
      return cb(err);
    }

    cb(null, result.rows[0]);
  });
}

function addBookmarkToCollection(client, bookmarkId, collectionId, cb) {
  client.query('INSERT INTO bookmark_collections(bookmark_id, collection_id) values($1, $2)', [
    bookmarkId, collectionId
  ], function(err) {
    if (err) {
      return cb(err);
    }

    cb(null);
  });
}

function removeBookmarkFromCollection(client, bookmarkId, collectionId, cb) {
  client.query('DELETE FROM bookmark_collections WHERE bookmark_id=($1) AND collection_id=($2)', [
    bookmarkId, collectionId
  ], function(err) {
    if (err) {
      return cb(err);
    }

    cb(null);
  });
}

module.exports = {
  connect: connect,
  createCollection: createCollection,
  getCollections: getCollections,
  getCollection: getCollection,
  updateCollection: updateCollection,
  deleteCollection: deleteCollection,
  createVenue: createVenue,
  createBookmark: createBookmark,
  updateBookmark: updateBookmark,
  addBookmarkToCollection: addBookmarkToCollection,
  removeBookmarkFromCollection: removeBookmarkFromCollection
};
