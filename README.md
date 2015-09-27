# Elm Yelp App

Small app built with Elm and the Yelp API.

## Quickstart

Make sure you have [Elm](http://elm-lang.org/) installed.

Clone this repository and install dependencies with:

```bash
$ elm-package install
$ npm install
```

### Frontend

Build the app by running:

```bash
$ elm-make src/Main.elm
```

Start the frontend server with:

```bash
$ npm run frontend
```

Navigate to `http://localhost:8000`.

### Backend

You will need [Yelp API access](https://www.yelp.com/developers/manage_api_keys) to run the backend.

Create a helper script `tmp/env.sh` to load your Yelp API credentials, and allow the frontend origin:

```bash
# tmp/env.sh
export CONSUMER_KEY='...'
export CONSUMER_SECRET='...'
export TOKEN='...'
export TOKEN_SECRET='...'
export CORS_ALLOW_ORIGIN='http://localhost:8000'
```

Start the backend server with:

```bash
$ source tmp/env.sh
$ npm run backend
