# lita-statuspage

[![Build Status](https://travis-ci.org/esigler/lita-statuspage.png?branch=master)](https://travis-ci.org/esigler/lita-statuspage)
[![Code Climate](https://codeclimate.com/github/esigler/lita-statuspage.png)](https://codeclimate.com/github/esigler/lita-statuspage)
[![Coverage Status](https://coveralls.io/repos/esigler/lita-statuspage/badge.png?branch=master)](https://coveralls.io/r/esigler/lita-statuspage?branch=master)

Statuspage.io (http://statuspage.io) handler for updating incidents, service status, etc.

## Installation

Add lita-statuspage to your Lita instance's Gemfile:

``` ruby
gem "lita-statuspage"
```

## Configuration

You'll need to get an API key and your Page ID, instructions for how to do so are here:
http://doers.statuspage.io/api/authentication/

Add the following variable to your Lita config file:

``` ruby
config.handlers.statuspage.api_key = '_your_key_here_'
config.handlers.statuspage.page_id = '_your_page_id_here_'
```

## Usage

### Overview

A quick "everything's hit the fan" example of how to use this plugin:
```
Lita > Lita statuspage incident new name:"Site unavailable" message:"We're looking into it now"
Incident ABC123 created
Lita > Lita statuspage incident update id:ABC123 message:"The database server has crashed, rebooting now" status:identified impact:critical
Incident ABC123 updated
Lita > Lita statuspage incident update id:ABC123 message:"Database server recovered, the site is back" status:resolved
Incident ABC123 updated
Lita > Lita statuspage incident list unresolved
No incidents to list
```

**Note:** This plugin also accepts `sp` as the command instead of `statuspage`

### Incidents

#### Create

```
Lita statuspage incident new name:"<name>"       - Create a new realtime incident
                             status:<status>     - (Optional) One of: investigating|identified|monitoring|resolved (default: investigating)
                             message:"<message>" - (Optional) The initial message
                             twitter:<state>     - (Optional) Post the new incident to Twitter, one of (true|t|false|f) (default:false)
                             impact:<state>      - (Optional) Override calculated impact value, one of: (minor|major|critical)
```

#### Update

```
Lita statuspage incident update id:<id>      - Update an incident
                         status:<status>     - (Optional) One of (investigating|identified|monitoring|resolved) (if realtime) or (scheduled|in_progress|verifying|completed) (if scheduled)
                         message:"<message>" - (Optional) The body of the new incident update that will be created
                         twitter:<state>     - (Optional) Post the new incident update to twitter, one of: (true|t|false|f) (default:false)
                         impact:<state>      - (Optional) Override calculated impact value, one of (minor|major|critical)
```

**NOTE:** If either of status or message is modified, a new incident update will be generated. You should update both of these attributes at the same time to avoid two separate incident updates being generated.

#### List

```
Lita statuspage incident list all        - List all incidents
Lita statuspage incident list scheduled  - List scheduled incidents
Lita statuspage incident list unresolved - List unresolved incidents
```

#### Delete

```
Lita statuspage incident delete latest  - Delete latest incident
Lita statuspage incident delete id:<id> - Delete a specific incident
```


### Components

#### List

```
Lita statuspage component list all                       - Lists all components
```

#### Update

```
Lita statuspage component update (id:<id>|name:"<name>") - Updates the component
                          status:<status>                - One of (operational|degraded_performance|partial_outage|major_outage|none)
```

## License

[MIT](http://opensource.org/licenses/MIT)
