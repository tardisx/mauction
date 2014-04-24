-- Verify initial_tables

BEGIN;

SELECT id, username, last_login, api_token FROM mauction.users WHERE false;
SELECT id, uid, session_expiry FROM mauction.sessions WHERE false;
SELECT id, user_id, name, description, bid_increment, bid_min, start_ts, end_ts, current_winner, current_price FROM mauction.items WHERE false;
SELECT id, item_id, imgur_code FROM mauction.imgur_pictures WHERE false;
SELECT id, user_id, item_id, ts, amount FROM mauction.bids WHERE false;

-- XXX should check functions and triggers too...

ROLLBACK;
