MAuction - Mojolicious Auction
==============================

The easy-to-use, perl/Mojolicious based auction site-in-a-box.

MAuction is designed to work well for:

* office environments
* online communities
* charities

Basically anywhere you have a bunch of users, just waiting to buy and sell
their stuff via eBay style auctions.

MAuction does not provide a separate user database, instead it is designed to
authenticate against your existing userbase. Integrating it is a snap, and
your users will love not having to setup Yet Another Account.

Dependencies
------------

* perl
* postgresql
* Mojolicious
* Rose::DB::Object
* DBI
* DBD::Pg
* an Authen::Simple::* module for your required authentication method.

