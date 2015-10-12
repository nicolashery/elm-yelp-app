module App where

import Debug
import Effects exposing (Effects)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Json
import Maybe
import Result
import Store exposing (Store)
import Task
import Yelp


-- MODEL --

type alias Model =
  { businesses : List Yelp.Business
  , term : String
  , location : String
  , isLoading : Bool
  , hasError : Bool
  , hasNoResults : Bool
  , store : Maybe Store
  }

init : (Model, Effects Action)
init =
  ( { businesses = []
    , term = ""
    , location = "Montréal, QC"
    , isLoading = False
    , hasError = False
    , hasNoResults = False
    , store = Nothing
    }
  --, Effects.batch [ getStore, search "bars" "Montréal, QC" ]
  -- Comment and uncomment above to immediately search, for development
  , getStore
  )

-- UPDATE --

type Action
  = UpdateTerm String
  | UpdateLocation String
  | StartSearch
  | CompleteSearch (Result Http.Error Yelp.SearchResponse)
  | CompleteGetStore (Result Http.Error Store)

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
              Ok response -> response.businesses
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

    CompleteGetStore result ->
      let store =
            case result of
              Err _ -> Nothing
              Ok store -> Just store
          -- Uncomment to debug Http or Json decoding errors
          --error =
          --  case result of
          --    Err error -> Just (Debug.log "error" error)
          --    Ok _ -> Nothing
      in
        ( { model | store <- store }
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

businessesView : List Yelp.Business -> Html
businessesView businesses =
  div [] (List.map businessView businesses)

businessView : Yelp.Business -> Html
businessView business =
  div [ class "search-venue" ]
    [ div [ class "search-venue-name" ] [ text business.name ]
    , locationView business
    , categoriesView business
    ]

locationView : Yelp.Business -> Html
locationView business =
  let location = business.location
      address = Maybe.withDefault [] location.address
      neighborhoods = Maybe.withDefault [] location.neighborhoods
      city = location.city
  in
    div []
      [ div [ class "search-venue-address1" ]
        (commaSeparatedView address)
      , div [ class "search-venue-address2" ]
        (commaSeparatedView (List.append neighborhoods [city]))
      ]

categoriesView : Yelp.Business -> Html
categoriesView business =
  let categories = Maybe.withDefault [] business.categories
      categoryName = \(name, alias) -> name
  in
    div [ class "search-venue-categories" ]
      (commaSeparatedView (List.map categoryName categories))

commaSeparatedView : List String -> List Html
commaSeparatedView strings =
  List.intersperse (span [] [text ", "])
    (List.map (\s -> span [] [text s]) strings)

-- EFFECTS --

search : String -> String -> Effects Action
search term location =
  Http.get Yelp.decodeSearchResponse (searchUrl term location)
    |> Task.toResult
    |> Task.map CompleteSearch
    |> Effects.task

apiUrl : String -> String
apiUrl path =
  "http://localhost:8001/v1" ++ path

searchUrlBase : String
searchUrlBase =
   --"/data/search.json"
  -- Comment and uncomment above to bypass remote API, for development
  apiUrl "/search"

searchUrl : String -> String -> String
searchUrl term location =
  Http.url searchUrlBase
    [ ("term", term)
    , ("location", location)
    ]

getStore : Effects Action
getStore =
  Http.get Store.decodeStore (apiUrl "/store")
    |> Task.toResult
    |> Task.map CompleteGetStore
    |> Effects.task
