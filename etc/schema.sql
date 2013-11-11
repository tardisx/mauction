DROP VIEW items_winners;
DROP TABLE bids;
DROP TABLE items;
DROP TABLE sessions;
DROP TABLE users;
DROP FUNCTION current_winner_for_item(this_item_id INT);
DROP TYPE user_bid;

CREATE TABLE users (
  id         SERIAL NOT NULL PRIMARY KEY,
  username   TEXT   NOT NULL UNIQUE,
  last_login TIMESTAMP NOT NULL,
  api_token  TEXT            UNIQUE
);
CREATE UNIQUE INDEX lower_username ON users (lower(username));

CREATE TABLE sessions (
  id              SERIAL NOT NULL PRIMARY KEY,
  uid             INT NOT NULL REFERENCES "users"(id),
  session_expiry  TIMESTAMP,
  session         TEXT
);


CREATE TABLE items (
  id              SERIAL        NOT NULL PRIMARY KEY,
  user_id         INT           NOT NULL REFERENCES users(id),
  name            TEXT          NOT NULL,
  description     TEXT          NOT NULL,
  bid_increment   NUMERIC(5,2 ) NOT NULL,
  bid_min  NUMERIC(7,2)         NOT NULL,
  start_ts        TIMESTAMP     NOT NULL,
  end_ts          TIMESTAMP     NOT NULL
);

CREATE TABLE bids (
  id        SERIAL          NOT NULL PRIMARY KEY,
  user_id  INT              NOT NULL REFERENCES users(id),
  item_id   INT             NOT NULL REFERENCES items(id),
  ts        TIMESTAMP       NOT NULL,
  amount    NUMERIC(7,2)    NOT NULL
);

CREATE TYPE user_bid AS (user_id INT, amount NUMERIC(7,2)); -- a user and amount
CREATE OR REPLACE FUNCTION current_winner_for_item(this_item_id INT) RETURNS user_bid AS
$$
  DECLARE
    item        items%ROWTYPE;
    bid         bids%ROWTYPE;
    bid_count   INT;

    -- these for when we iterate
    winner_proxy    user_bid;
    winner_highest  user_bid;
    this_bid        user_bid;
  BEGIN
    -- fetch all bids
    SELECT count(*) FROM bids WHERE bids.item_id = this_item_id INTO bid_count;
    -- fetch the item
    SELECT * FROM items WHERE items.id = this_item_id INTO item;

    -- algorithm:
    --  * if no bids, return NULL
    --  * if one bid, return item.bid_min
    IF bid_count = 0 THEN
      return NULL;
    ELSE
      --  * for n bids, iterate through calculating the winner and winning bid along the way
      FOR bid IN (SELECT * FROM bids WHERE bids.item_id = this_item_id ORDER BY ts)
      LOOP
        this_bid.user_id = bid.user_id;
        this_bid.amount  = bid.amount;

        -- if we just had one bidder, special case
        IF bid_count = 1 THEN
          -- proxy win is the minimum, highest is what they bid
          winner_highest.amount  = bid.amount;
          winner_highest.user_id = bid.user_id;
          winner_proxy.amount    = item.bid_min;
          winner_proxy.user_id   = bid.user_id;
          return winner_proxy;
        END IF;

        -- first time in loop, first bidder wins by the minimum
        IF winner_proxy IS NULL THEN
          winner_highest.amount  = bid.amount;
          winner_highest.user_id = bid.user_id;
          winner_proxy.amount    = item.bid_min;
          winner_proxy.user_id   = bid.user_id;

        -- next case, they bid more than the proxy winner, but less than the highest amount
        ELSEIF this_bid.amount > winner_proxy.amount AND this_bid.amount < winner_highest.amount AND winner_proxy.user_id != this_bid.user_id THEN
          winner_proxy.amount  = this_bid.amount + item.bid_increment; -- xxx edge case of slightly below max?
          -- winner does not change  

        -- next case, they bid more than the proxy winners highest bid
        ELSEIF this_bid.amount > winner_highest.amount AND winner_proxy.user_id != this_bid.user_id THEN
          winner_proxy.amount = winner_highest.amount + item.bid_increment;
          winner_proxy.user_id = this_bid.user_id;
          winner_highest = this_bid;

        ELSE
          RAISE NOTICE ' not sure about  % % %', this_bid, winner_proxy, winner_highest;
        END IF;

      END LOOP;
    END IF;
    RETURN winner_proxy;
  END;
$$ LANGUAGE plpgsql;

CREATE VIEW items_winners AS
  SELECT items.*, current_winner_for_item(id)
    FROM items;


CREATE OR REPLACE FUNCTION validate_bid() RETURNS TRIGGER
AS $$
    DECLARE
      current_winner user_bid;
      last_bid   bids%ROWTYPE;
      this_user_last_bid   bids%ROWTYPE;
      item       items%ROWTYPE;
    BEGIN
      IF (TG_OP = 'DELETE') THEN
        RAISE EXCEPTION 'bids cannot be deleted';

      ELSEIF (TG_OP = 'UPDATE') THEN
        RAISE EXCEPTION 'bids cannot be changed';

      ELSEIF (TG_OP = 'INSERT') THEN
        NEW.ts = CURRENT_TIMESTAMP;   -- you don't get to choose your bid time

        SELECT * FROM bids  WHERE item_id = NEW.item_id ORDER BY ts DESC LIMIT 1 INTO last_bid;
        SELECT * FROM bids  WHERE item_id = NEW.item_id and user_id = NEW.user_id ORDER BY TS DESC LIMIT 1 INTO this_user_last_bid;
        SELECT * FROM items WHERE id = NEW.item_id INTO item;

        current_winner = current_winner_for_item(NEW.item_id);

        IF NEW.ts > item.end_ts THEN
          RAISE EXCEPTION 'item is closed';
        END IF;

        IF NEW.ts < item.start_ts THEN
          RAISE EXCEPTION 'item is not yet open';
        END IF;

        IF NEW.user_id = item.user_id THEN
          RAISE EXCEPTION 'users cannot bid on their own items';
        END IF;

        IF current_winner.amount IS NULL AND NEW.amount < item.bid_min THEN
          RAISE EXCEPTION 'bid is not at least the minimum bid amount';
        END IF;

        IF current_winner.amount IS NOT NULL AND  NEW.amount < current_winner.amount + item.bid_increment THEN
          RAISE EXCEPTION 'bid of % does not exceed winning bid of % by at least %', NEW.amount, current_winner.amount,  item.bid_increment;
        END IF;

        -- you can't lower a previous bid
        IF NEW.amount <= this_user_last_bid.amount THEN
          RAISE EXCEPTION 'you cannot bid lower than your previous bids';
        END IF;

      END IF;

      RETURN NEW;

    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validate_bid BEFORE INSERT OR UPDATE OR DELETE ON bids
  FOR EACH ROW EXECUTE PROCEDURE validate_bid();


