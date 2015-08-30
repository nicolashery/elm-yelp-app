# Elm Yelp App

Small app built with Elm and the Yelp API.

## Quickstart

### Frontend

Make sure you have [Elm](http://elm-lang.org/) installed. Clone this repository then run:

```bash
$ elm-reactor
```

Navigate to `http://localhost:8000/src/Main.elm`.

### Backend

You will need [Yelp API access](https://www.yelp.com/developers/manage_api_keys) to run the backend.

Install dependencies with:

```bash
$ npm install
```

Create a helper script `tmp/env.sh` to load your Yelp API credentials:

```bash
# tmp/env.sh
export CONSUMER_KEY='...'
export CONSUMER_SECRET='...'
export TOKEN='...'
export TOKEN_SECRET='...'
```

Start the backend with:

```bash
$ source tmp/env.sh
$ npm start
