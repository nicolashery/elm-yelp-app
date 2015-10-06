-- Sets up a new database

-- Using `uuid_generate_v1mc()` to get UUID primary keys with lower keyspace fragmentation
-- See: https://blog.starkandwayne.com/2015/05/23/uuid-primary-keys-in-postgresql/

-- Columns `created_at` and `updated_at` are stored
-- without timezone information (timestamp is UTC)

CREATE EXTENSION 'uuid-ossp';

CREATE OR REPLACE FUNCTION set_updated_at_column() RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = current_timestamp AT TIME ZONE 'UTC';
   RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TABLE collections(
  id UUID PRIMARY KEY DEFAULT uuid_generate_v1mc(),
  created_at TIMESTAMP NOT NULL DEFAULT (current_timestamp AT TIME ZONE 'UTC'),
  updated_at TIMESTAMP NOT NULL DEFAULT (current_timestamp AT TIME ZONE 'UTC'),
  name TEXT NOT NULL,
  description TEXT NOT NULL
);

CREATE TRIGGER set_updated_at_collections
  BEFORE UPDATE ON collections FOR EACH ROW
  EXECUTE PROCEDURE set_updated_at_column();

CREATE TABLE venues(
  id UUID PRIMARY KEY DEFAULT uuid_generate_v1mc(),
  created_at TIMESTAMP NOT NULL DEFAULT (current_timestamp AT TIME ZONE 'UTC'),
  updated_at TIMESTAMP NOT NULL DEFAULT (current_timestamp AT TIME ZONE 'UTC'),
  yelp_id TEXT NOT NULL
);

CREATE TRIGGER set_updated_at_venues
  BEFORE UPDATE ON venues FOR EACH ROW
  EXECUTE PROCEDURE set_updated_at_column();

CREATE TABLE bookmarks(
  id UUID PRIMARY KEY DEFAULT uuid_generate_v1mc(),
  created_at TIMESTAMP NOT NULL DEFAULT (current_timestamp AT TIME ZONE 'UTC'),
  updated_at TIMESTAMP NOT NULL DEFAULT (current_timestamp AT TIME ZONE 'UTC'),
  venue_id UUID REFERENCES venues,
  notes TEXT NOT NULL
);

CREATE TRIGGER set_updated_at_bookmarks
  BEFORE UPDATE ON bookmarks FOR EACH ROW
  EXECUTE PROCEDURE set_updated_at_column();

CREATE TABLE collection_bookmarks(
  created_at TIMESTAMP NOT NULL DEFAULT (current_timestamp AT TIME ZONE 'UTC'),
  collection_id UUID REFERENCES collections,
  bookmarks_id UUID REFERENCES bookmarks
);
