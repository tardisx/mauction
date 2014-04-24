-- Revert initial_tables

BEGIN;

DROP TABLE mauction.bids;
DROP TABLE mauction.imgur_pictures;
DROP TABLE mauction.items;
DROP TABLE mauction.sessions;
DROP TABLE mauction.users;
DROP FUNCTION mauction.current_winner_for_item(this_item_id INT);
DROP TYPE mauction.user_bid;

COMMIT;
