module Yelp where

import Json.Decode as Json exposing ((:=))

type alias Location =
  { address : Maybe (List String)
  , neighborhoods : Maybe (List String)
  , city: String
  }

type alias BusinessId = String

type alias Business =
  { id : BusinessId
  , name : String
  , location : Location
  , categories : Maybe (List (String, String))
  }

type alias SearchResponse =
  { businesses : List Business }

decodeSearchResponse : Json.Decoder SearchResponse
decodeSearchResponse =
  Json.object1 SearchResponse
    ("businesses" := (Json.list decodeBusiness))

decodeBusiness : Json.Decoder Business
decodeBusiness =
  Json.object4 Business
    ("id" := Json.string)
    ("name" := Json.string)
    ("location" := decodeLocation)
    (Json.maybe ("categories" := Json.list decodeCategory))

decodeLocation : Json.Decoder Location
decodeLocation =
  Json.object3 Location
    (Json.maybe ("address" := (Json.list Json.string)))
    (Json.maybe ("neighborhoods" := (Json.list Json.string)))
    ("city" := Json.string)

decodeCategory : Json.Decoder (String, String)
decodeCategory =
  Json.tuple2 (,) Json.string Json.string
