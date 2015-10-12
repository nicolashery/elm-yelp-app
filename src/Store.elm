module Store where

import Dict exposing (Dict)
import Json.Decode as Json exposing ((:=))
import Yelp

type alias Timestamp = String
type alias BookmarkId = String
type alias CollectionId = String

type alias Bookmark =
  { id : BookmarkId
  , createdAt : Timestamp
  , updatedAt : Timestamp
  , notes : String
  , yelpId : Yelp.BusinessId
  , collectionIds: List CollectionId
  }

type alias Collection =
  { id : CollectionId
  , createdAt : Timestamp
  , updatedAt : Timestamp
  , name : String
  , description : String
  }

type alias Store =
  { bookmarks : Dict BookmarkId Bookmark
  , collections : Dict CollectionId Collection
  , yelp : Dict Yelp.BusinessId Yelp.Business
  }

decodeStore : Json.Decoder Store
decodeStore =
  Json.object3 Store
    ("bookmarks" := Json.dict decodeBookmark)
    ("collections" := Json.dict decodeCollection)
    ("yelp" := Json.dict Yelp.decodeBusiness)

decodeBookmark : Json.Decoder Bookmark
decodeBookmark =
  Json.object6 Bookmark
    ("id" := Json.string)
    ("created_at" := Json.string)
    ("updated_at" := Json.string)
    ("notes" := Json.string)
    ("yelp_id" := Json.string)
    ("collection_ids" := Json.list Json.string)

decodeCollection : Json.Decoder Collection
decodeCollection =
  Json.object5 Collection
    ("id" := Json.string)
    ("created_at" := Json.string)
    ("updated_at" := Json.string)
    ("name" := Json.string)
    ("description" := Json.string)
