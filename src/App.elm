module App where

import Debug
import Effects exposing (Effects)
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Json.Decode as Json exposing ((:=))
import Maybe
import Result
import Task


-- MODEL --

type alias Business =
  { id : String
  , name : String
  , categories : List (String, String)
  }

type alias Model = { businesses : List Business }

init : (Model, Effects Action)
init =
  ( Model []
  , search "bars" "Montréal"
  )


-- UPDATE --

type Action = NewSearchResults (Maybe (List Business))

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    NewSearchResults maybeResults ->
      let businesses =  Maybe.withDefault [] maybeResults
      in
        ( { model | businesses <- businesses }
        , Effects.none
        )


-- VIEW --

view : Signal.Address Action -> Model -> Html
view address model =
  div []
  (List.map businessView model.businesses)

businessView : Business -> Html
businessView business =
  div []
  [ h2 [] [text business.name]
  , div []
  ( List.intersperse (span [] [text ", "])
   (List.map categoryView business.categories)
  )
  ]

categoryView : (String, String) -> Html
categoryView (cateogryName, categoryAlias) =
  a [href ("#" ++ categoryAlias)]
  [ text cateogryName
  ]


-- EFFECTS --

search : String -> String -> Effects Action
search term location =
  Http.get decodeResults (searchUrl term location)
    |> Task.toMaybe
    |> Task.map NewSearchResults
    |> Effects.task

searchUrl : String -> String -> String
searchUrl term location =
  Http.url "/search.json"
    [ ("term", term)
    , ("location", location)
    ]

decodeResults : Json.Decoder (List Business)
decodeResults =
  ("businesses" := (Json.list decodeBusiness))

decodeCategory : Json.Decoder (String, String)
decodeCategory =
  Json.tuple2 (,) Json.string Json.string

decodeBusiness : Json.Decoder Business
decodeBusiness =
  Json.object3 Business
    ("id" := Json.string)
    ("name" := Json.string)
    ("categories" := Json.list decodeCategory)
