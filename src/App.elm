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
  , address : List String
  , neighborhoods : List String
  , categories : List (String, String)
  }

type alias Model =
  { businesses : List Business
  , term : String
  , location : String
  , isLoading : Bool
  , hasError : Bool
  , hasNoResults : Bool
  }

init : (Model, Effects Action)
init =
  ( { businesses = []
    , term = ""
    , location = "Montréal, QC"
    , isLoading = False
    , hasError = False
    , hasNoResults = False
    }
  --, search "bars" "Montréal, QC"
  -- Comment and uncomment above to immediately search, for development
  , Effects.none
  )


-- UPDATE --

type Action
  = UpdateTerm String
  | UpdateLocation String
  | StartSearch
  | CompleteSearch (Result Http.Error (List Business))

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

    StartSearch ->
      ( { model
          | businesses <- []
          , isLoading <- True
          , hasError <- False
          , hasNoResults <- False }
      , search model.term model.location
      )

    CompleteSearch result ->
      let businesses =
            case result of
              Err _ -> []
              Ok value -> value
          hasError =
            case result of
              Err _ -> True
              Ok _ -> False
          hasNoResults = not hasError && List.isEmpty businesses
          -- Uncomment to debug Http or Json decoding errors
          --error =
          --  case result of
          --    Err error -> Just (Debug.log "error" error)
          --    Ok _ -> Nothing
      in
        ( { model
            | businesses <- businesses
            , isLoading <- False
            , hasError <- hasError
            , hasNoResults <- hasNoResults }
        , Effects.none
        )

-- VIEW --

view : Signal.Address Action -> Model -> Html
view address model =
  div [ class "container app" ]
    [ searchFormView address model.term model.location model.isLoading
    , loadingView model.isLoading
    , errorView model.hasError
    , noResultsView model.term model.hasNoResults
    , businessesView model.businesses
    ]

searchFormView : Signal.Address Action -> String -> String -> Bool -> Html
searchFormView address term location isLoading =
  Html.form [ class "search-form" ]
    [
      label [ for "term" ] [ text "Find " ]
    , input
        [ id "term"
        , type' "text"
        , class "u-full-width"
        , value term
        , on "input" targetValue (Signal.message address << UpdateTerm)
        ]
        []
    , label [ for "location" ] [ text "Near " ]
    , input
        [ id "location"
        , type' "text"
        , class "u-full-width"
        , value location
        , on "input" targetValue (Signal.message address << UpdateLocation)
        ]
        []
    , button
      [ class "button-primary u-full-width"
      , onWithOptions
          "click"
          { defaultOptions | preventDefault <- True }
          Json.value
          (\_ -> Signal.message address StartSearch)
      , disabled isLoading
      ]
      [ text "Search" ]
    ]

loadingView : Bool -> Html
loadingView isLoading =
  div [ class "search-loading"
      , style [ ("display", if isLoading then "block" else "none") ]
      ]
    [ text "Loading..." ]

errorView : Bool -> Html
errorView hasError =
  div [ class "alert alert-error"
      , style [ ("display", if hasError then "block" else "none") ]
      ]
    [ text ("Oops! An error occured while searching.") ]

noResultsView : String -> Bool -> Html
noResultsView term hasNoResults =
  div [ class "search-no-results"
      , style [ ("display", if hasNoResults then "block" else "none") ]
      ]
    [ text ("Could not find any results for \"" ++ term ++ "\"!") ]

businessesView : List Business -> Html
businessesView businesses =
  div [] (List.map businessView businesses)

businessView : Business -> Html
businessView business =
  div [ class "search-business" ]
    [ div [ class "search-business-name" ] [ text business.name ]
    , div [ class "search-business-address" ]
      (commaSeparatedView business.address)
    , div [ class "search-business-neighborhoods" ]
      (commaSeparatedView business.neighborhoods)
    , div [ class "search-business-categories" ]
      ( commaSeparatedView
        (List.map (\(name, alias) -> name) business.categories)
      )
    ]

commaSeparatedView : List String -> List Html
commaSeparatedView strings =
  List.intersperse (span [] [text ", "])
    (List.map (\s -> span [] [text s]) strings)

-- EFFECTS --

search : String -> String -> Effects Action
search term location =
  Http.get decodeResults (searchUrl term location)
    |> Task.toResult
    |> Task.map CompleteSearch
    |> Effects.task

searchUrlBase : String
searchUrlBase =
   --"/data/search.json"
  -- Comment and uncomment above to bypass remote API, for development
  "http://localhost:8001/search"

searchUrl : String -> String -> String
searchUrl term location =
  Http.url searchUrlBase
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
  Json.object5 Business
    ("id" := Json.string)
    ("name" := Json.string)
    (Json.at ["location", "address"] (Json.list Json.string))
    (Json.oneOf [ Json.at ["location", "neighborhoods"] (Json.list Json.string)
                , Json.succeed [] ])
    ("categories" := Json.list decodeCategory)
