DROP TABLE bids;
DROP TABLE items;
DROP TABLE users;

CREATE TABLE users (
  id         SERIAL NOT NULL PRIMARY KEY,
  username   TEXT   NOT NULL UNIQUE
);

CREATE TABLE items (
  id              SERIAL        NOT NULL PRIMARY KEY,
  user_id        INT           NOT NULL REFERENCES users(id),
  name            TEXT          NOT NULL,
  description     TEXT          NOT NULL,
  bid_increment   NUMERIC(5,2 ) NOT NULL,
  bid_min  NUMERIC(7,2)  NOT NULL,
  start_ts        TIMESTAMP     NOT NULL,
  end_ts          TIMESTAMP     NOT NULL
);

CREATE TABLE bids (
  id        SERIAL          NOT NULL PRIMARY KEY,
  user_id  INT             NOT NULL REFERENCES users(id),
  item_id   INT             NOT NULL REFERENCES items(id),
  ts        TIMESTAMP       NOT NULL,
  amount    NUMERIC(7,2)    NOT NULL  -- XXX trigger to ensure this is greater than the last by some fixed amount, and >0
);


CREATE OR REPLACE FUNCTION validate_bid() RETURNS TRIGGER
AS $$
    DECLARE
      last_bid   bids%ROWTYPE;
      item       items%ROWTYPE;
    BEGIN
      IF (TG_OP = 'DELETE') THEN
        RAISE EXCEPTION 'bids cannot be deleted';

      ELSEIF (TG_OP = 'UPDATE') THEN
        RAISE EXCEPTION 'bids cannot be changed';

      ELSEIF (TG_OP = 'INSERT') THEN
        NEW.ts = CURRENT_TIMESTAMP;   -- you don't get to choose your bid time

        SELECT * FROM bids  WHERE item_id = NEW.item_id ORDER BY ts DESC LIMIT 1 INTO last_bid;
        SELECT * FROM items WHERE id = NEW.item_id INTO item;

        IF NEW.amount < item.bid_min THEN
          RAISE EXCEPTION 'bid is not at least the minimum bid amount';
        END IF;

        IF NEW.amount < last_bid.amount + item.bid_increment THEN
          RAISE EXCEPTION 'bid does not exceed previous bid by at least %', item.bid_increment;
        END IF;

        IF NEW.ts > item.end_ts THEN
          RAISE EXCEPTION 'item is closed';
        END IF;

        IF NEW.ts < item.start_ts THEN
          RAISE EXCEPTION 'item is not yet open';
        END IF;

        IF NEW.user_id = item.user_id THEN
          RAISE EXCEPTION 'users cannot bid on their own items';
        END IF;

      END IF;

      RETURN NEW;

    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validate_bid BEFORE INSERT OR UPDATE OR DELETE ON bids
  FOR EACH ROW EXECUTE PROCEDURE validate_bid();
