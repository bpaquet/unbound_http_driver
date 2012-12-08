unbound_http_driver
===================

Http interface for configuring unbound DNS server : allow to configure local_zone through with simple HTTP calls.

# How to use it ?

* Install dependencies: `bundle`
* Give read permission for current user on `/etc/unbound/unbound_control.key`, `/etc/unbound/unbound_control.pem`, `/etc/unbound/unbound_server.pem`
* Give write permission for current user on `/etc/unbound/unbound.conf`
* Launch app: `LOCAL_DB=/tmp/unbound.yml rackup`. The `LOCAL_DB` is the database file used by unbound_http_driver
You can launch it with `rackup`.

On the first launch, the database file is filled with current unbound config.

The `server_config` section of the database file can be edited manually to add more unbound options.

# API

* `GET /`: display current configuration in JSON
* `POST /reload`: reload unbound configuration from current database
* `PUT /toto.com/www/10.10.0.1`: add A record `www.toto.com` to `10.10.0.1`
* `DELETE /toto.com/www`: delete A record `www.toto.com`
* `GET /toto.com`: display content of zone `toto.com` in JSON

