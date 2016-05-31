# Sojourn [![Build Status](https://img.shields.io/travis/HireArt/sojourn.svg)](https://travis-ci.org/HireArt/sojourn) [![Code Climate](https://img.shields.io/codeclimate/github/HireArt/sojourn.svg)](https://codeclimate.com/github/HireArt/sojourn) [![Test Coverage](https://img.shields.io/codeclimate/coverage/github/HireArt/sojourn.svg)](https://codeclimate.com/github/HireArt/sojourn/coverage)

Simple source & event tracking for Rails. This gem automatically tracks *sojourners*
(i.e. unique visitors) based on:

* Referer
* UTM parameters
* Browser (User Agent)
* The currently logged-in user (i.e. `current_user`)
* Various other request data

## How It Works

Whenever a new visitor ("sojourner") arrives to the site, an event is tracked containing
basic data about their browser and where they came from. Similar events are also tracked
whenever a user logs in, logs out, or visits again from an external site. In addition,
you can track a custom event anytime a visitor does something of interest to you.

Ultimately, rather than storing parts of the data in separate tables, **all data is
tracked in the form of events.** Yep, events all the way down. (See 'Why Events?' below
for the reasoning behind this.)

Sojourn assigns each "sojourner" a UUID, which is tracked across requests. All events are
associated with this UUID and with the current user's ID (if logged-in). The current
request is also assigned a UUID (which defaults to the `X-Request-ID` header).

Events consist of an event name (defining a collection of events), a session UUID,
and a set of properties (key-value data) which includes information about the request.
In the PostgreSQL implementation, we use a `JSONB` column to store the key-value data.

## Usage

```ruby
# Track a custom event (highly encouraged!):
sojourn.track! 'clicked call-to-action', plan_choice: 'enterprise'

# Read events using ActiveRecord
e = Sojourn::Event.last
e.name               # event name (e.g. 'clicked call-to-action')
e.sojourner_uuid     # uuid tracked across requests, stored in cookie
e.user               # User or nil
e.properties         # key-value hash (e.g. "{ plan_choice: 'enterprise' }")

# If you don't have access to a controller context (i.e. the event is not occurring during a web
# request), you can still track a raw event like this:
Sojourn.track_raw_event! 'subscription expired', plan: 'enterprise', customer_id: 'xyb123'
```

## Default Events

The three built-in events are as follows:

```ruby
'!sojourning' # The sojourner has arrived from an external source.
'!logged_in'  # The sojourner has logged-in.
'!logged_out' # The sojourner has logged-out.
```

A `'!sojourning'` event takes place whenever any of the following conditions is met:

* The sojourner has never been seen before (i.e. direct traffic of some kind)
* The referer is from an external source (i.e. not the current `request.host`)
* The request contains tracked (utm-style) parameters. (These can be configured in the `sojourn.rb`
  initializer.)


## Properties

In addition to properties that you manually add, events will automatically include data about
the current web request. An example looks like this:

```json
{
  "custom_property":"value",
  "request":{
    "uuid":"5e698f6ca74a016c49ca6b91a79cada7",
    "host":"example.com",
    "path":"/my-news",
    "controller":"news",
    "action":"index",
    "method":"get",
    "params":{
      "utm_campaign":"daily_updates",
      "page":"1"
    },
    "referer":"https://mail.google.com",
    "ip_address":"42.42.42.42",
    "user_agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2564.48 Safari/537.36"
  },
  "browser":{
    "bot":false,
    "name":"Chrome",
    "known":true,
    "version":"48",
    "platform":"mac"
  },
  "campaign":{
    "utm_campaign":"daily_updates"
  }
}
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sojourn'
```

And then execute:

    $ bundle

To install migrations and the `sojourn.rb` initializer, execute:

    $ rails g sojourn:install

## Why Events? Why not track visits/visitors as their own objects?

The idea is that, at a certain scale, this kind of tracking should be dumped directly into
append-only logs (or an event bus / messaging queue) for asynchronous processing.

This is made easier when everything can be represented, at a basic level, as a set of discrete
events. In theory, it works with just about any data store, and makes for easy time series and
funnel analysis. I'd like to move away from ActiveRecord at some point and open up the door for
other, more horizontally scalable data backends, ideally with a focus on streaming data (e.g.
Kafka combined with Samza or Storm).

An added benfit of storing the start of each visit as its own event in the series (i.e. the
built-in `!sojourning` event) is that you can change the length of your visit window after
the fact and re-run your analysis. The more traditional approach is to tag each event with
some kind of incrementing visit ID, which forces you into defining what a "unique visit"
means for your product before you've even collected any data.

## Current Limitations (i.e. the 'todo' list)

* Tested only on rails 3.2.18 and ruby 2.0.0 with ActiveRecord and PostgreSQL.
* Assumes `User` and `current_user` convention for user tracking.
* Assumes that if `request.referer` does not match `request.host`, the referer is external to your
  website.
* Relies solely on cookies to track visitor UUID across requests (no JS, fingerprinting, etc)
* Relies on ActiveRecord for storage. (At a bigger scale, append-only logs are preferred)
