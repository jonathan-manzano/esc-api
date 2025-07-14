-- backend/sql/schema.sql: Defines the complete database structure.

BEGIN;

-- Create custom ENUM types for status fields.
CREATE TYPE booking_status AS ENUM ('available', 'locked', 'booked');
CREATE TYPE reservation_status AS ENUM ('pending_payment', 'confirmed', 'cancelled', 'completed');

-- Create extension for GIST indexing
CREATE EXTENSION btree_gist;

-- Table for business locations.
CREATE TABLE IF NOT EXISTS Locations
(
    id         BIGSERIAL PRIMARY KEY,
    name       VARCHAR(255) NOT NULL,
    address    TEXT,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- Table for the escape rooms.
CREATE TABLE IF NOT EXISTS Rooms
(
    id               BIGSERIAL PRIMARY KEY,
    location_id      BIGINT       REFERENCES Locations (id) ON DELETE SET NULL,
    name             VARCHAR(255) NOT NULL,
    description      TEXT,
    theme            VARCHAR(100),
    difficulty       SMALLINT CHECK (difficulty >= 1 AND difficulty <= 5),
    min_players      SMALLINT     NOT NULL DEFAULT 2,
    max_players      SMALLINT     NOT NULL DEFAULT 8,
    duration_minutes INTEGER      NOT NULL DEFAULT 60,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- Table for user accounts.
CREATE TABLE IF NOT EXISTS Users
(
    id            BIGSERIAL PRIMARY KEY,
    first_name    VARCHAR(100),
    last_name     VARCHAR(100),
    email         VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- Table for every unique, bookable instance of a room.
CREATE TABLE IF NOT EXISTS BookingSlots
(
    id         BIGSERIAL PRIMARY KEY,
    room_id    BIGINT         NOT NULL REFERENCES Rooms (id) ON DELETE CASCADE,
    start_time TIMESTAMPTZ    NOT NULL,
    end_time   TIMESTAMPTZ    NOT NULL,
    price      NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    status     booking_status NOT NULL DEFAULT 'available',
    created_at TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_room_time_slot EXCLUDE USING GIST (room_id WITH =, TSTZRANGE(start_time, end_time) WITH &&)
);

-- Table for reservations linking a User to a BookingSlot.
CREATE TABLE IF NOT EXISTS Reservations
(
    id                BIGSERIAL PRIMARY KEY,
    booking_slot_id   BIGINT             NOT NULL UNIQUE REFERENCES BookingSlots (id) ON DELETE CASCADE,
    user_id           BIGINT             NOT NULL REFERENCES Users (id) ON DELETE CASCADE,
    number_of_players SMALLINT           NOT NULL,
    status            reservation_status NOT NULL DEFAULT 'pending_payment',
    total_amount      NUMERIC(10, 2)     NOT NULL,
    booked_at         TIMESTAMPTZ        NOT NULL DEFAULT NOW()
);

-- Create indexes for faster lookups.
CREATE INDEX ON Rooms (location_id);
CREATE INDEX ON BookingSlots (room_id, start_time);
CREATE INDEX ON Reservations (user_id);
CREATE INDEX ON Reservations (booking_slot_id);

COMMIT;
