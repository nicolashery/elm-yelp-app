module App where

import Debug
import Effects exposing (Effects)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
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

type alias Model =
  { businesses : List Business
  , term : String
  , location : String
  }

init : (Model, Effects Action)
init =
  ( { businesses = [], term = "", location = "Montréal, QC" }
  , Effects.none
  )


-- UPDATE --

type Action
  = UpdateTerm String
  | UpdateLocation String
  | Search
  | NewSearchResults (Maybe (List Business))

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    UpdateTerm term ->
      ( { model | term <- term }
      , Effects.none
      )

    UpdateLocation location ->
      ( { model | location <- location }
      , Effects.none
      )

    Search ->
      ( model
      , search model.term model.location
      )

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
    ( [searchFormView address model.term model.location]
    ++ (List.map businessView model.businesses)
    )

searchFormView : Signal.Address Action -> String -> String -> Html
searchFormView address term location =
  Html.form []
    [
      label [] [ text "Find " ]
    , input
        [ value term
        , on "input" targetValue (Signal.message address << UpdateTerm)
        ]
        []
    , span [] [ text " near " ]
    , input
        [ value location
        , on "input" targetValue (Signal.message address << UpdateLocation)
        ]
        []
    , span [] [ text " " ]
    , button
      [ onWithOptions
          "click"
          { defaultOptions | preventDefault <- True }
          Json.value
          (\_ -> Signal.message address Search)
      ]
      [ text "Search" ]
    ]

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
  a [ href ("#" ++ categoryAlias) ] [ text cateogryName ]


-- EFFECTS --

search : String -> String -> Effects Action
search term location =
  Http.get decodeResults (searchUrl term location)
    |> Task.toMaybe
    |> Task.map NewSearchResults
    |> Effects.task

searchUrl : String -> String -> String
searchUrl term location =
  Http.url "http://localhost:8001/search"
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
