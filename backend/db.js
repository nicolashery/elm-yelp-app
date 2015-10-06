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

function createCollection(client, name, description, cb) {
  client.query('INSERT INTO collections(name, description) values($1, $2) RETURNING *', [
    name, description
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

module.exports = {
  connect: connect,
  createCollection: createCollection,
  getCollections: getCollections,
  getCollection: getCollection
};
