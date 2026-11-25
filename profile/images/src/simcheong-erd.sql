/* create schemas. */
CREATE SCHEMA account;
CREATE SCHEMA schedule;
CREATE SCHEMA closet;


/* create tables. */
CREATE TABLE account.profiles (
    user_id UUID NOT NULL,
    "name" VARCHAR(50),
    birth_date DATE,
    gender VARCHAR(20),
    job VARCHAR(50),
    height_cm NUMERIC(4, 1),
    weight_kg NUMERIC(4, 1),
    agent_name VARCHAR(30),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    call_name VARCHAR(30),
    speech_rate NUMERIC(3, 2),
    PRIMARY KEY (user_id)
);

CREATE TABLE account.push_tokens (
    id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY,
    user_id UUID NOT NULL,
    token TEXT NOT NULL UNIQUE,
    platform VARCHAR(10) NOT NULL,
    last_seen_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    PRIMARY KEY (id)
);

CREATE TABLE account.refresh_tokens (
    id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY,
    user_id UUID NOT NULL,
    token_hash CHAR(64) NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    revoked_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    PRIMARY KEY (id)
);

CREATE TABLE account.user_identities (
    id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY,
    user_id UUID NOT NULL,
    issuer VARCHAR(10) NOT NULL,
    subject VARCHAR(128) NOT NULL,
    sign_in_provider VARCHAR(10) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    CONSTRAINT user_identities_subject_uq UNIQUE (issuer, subject)
);

CREATE TABLE account.users (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    PRIMARY KEY (id)
);

CREATE TABLE closet.garment_defects (
    id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY,
    garment_id VARCHAR(40) NOT NULL,
    kind VARCHAR(20) NOT NULL,
    "location" VARCHAR(50),
    confidence NUMERIC(4, 3),
    checked_by VARCHAR(5),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    PRIMARY KEY (id)
);

CREATE TABLE closet.garments (
    id VARCHAR(40) NOT NULL,
    user_id UUID NOT NULL,
    category VARCHAR(10) NOT NULL,
    "name" VARCHAR(50) NOT NULL,
    color_name VARCHAR(30) NOT NULL,
    color_family VARCHAR(10) NOT NULL,
    tone VARCHAR(5) NOT NULL,
    formality VARCHAR(10) NOT NULL DEFAULT 'unknown',
    embedding REAL[],
    first_seen_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    last_seen_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    image_embedding REAL[],
    image_model VARCHAR(40),
    image_count INTEGER NOT NULL DEFAULT 0,
    thumbnail BYTEA,
    thumbnail_at TIMESTAMP WITH TIME ZONE,
    pattern VARCHAR(30),
    pattern_checked_by VARCHAR(5),
    pattern_guess VARCHAR(30),
    material VARCHAR(50),
    notes VARCHAR(500),
    sub_color_name VARCHAR(30),
    sub_color_family VARCHAR(10),
    PRIMARY KEY (id)
);

CREATE TABLE closet.style_docs (
    id UUID NOT NULL DEFAULT gen_random_uuid(),
    "content" TEXT NOT NULL,
    metadata JSON NOT NULL,
    embedding REAL[] NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE closet.wears (
    id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY,
    garment_id VARCHAR(40) NOT NULL,
    worn_on DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    CONSTRAINT wears_garment_day_uq UNIQUE (garment_id, worn_on)
);

CREATE TABLE schedule.events (
    id VARCHAR(40) NOT NULL,
    user_id UUID NOT NULL,
    title VARCHAR(200) NOT NULL,
    start_at TIMESTAMP WITH TIME ZONE NOT NULL,
    place VARCHAR(200),
    kakao_place_id VARCHAR(20),
    occasion VARCHAR(20) NOT NULL DEFAULT 'casual',
    occasion_source VARCHAR(10) NOT NULL DEFAULT 'default',
    notified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    care_reminded_at TIMESTAMP WITH TIME ZONE,
    remind BOOLEAN NOT NULL DEFAULT true,
    remind_days_before INTEGER,
    remind_time TIME WITHOUT TIME ZONE,
    PRIMARY KEY (id)
);

CREATE TABLE schedule.places (
    kakao_place_id VARCHAR(20) NOT NULL,
    place_name VARCHAR(200) NOT NULL,
    category VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (kakao_place_id)
);


/* create foreign keys. */
ALTER TABLE closet.garment_defects
    ADD FOREIGN KEY (garment_id)
    REFERENCES closet.garments (id)
    ON UPDATE NO ACTION
    ON DELETE CASCADE;

ALTER TABLE account.refresh_tokens
    ADD FOREIGN KEY (user_id)
    REFERENCES account.users (id)
    ON UPDATE NO ACTION
    ON DELETE CASCADE;

ALTER TABLE account.push_tokens
    ADD FOREIGN KEY (user_id)
    REFERENCES account.users (id)
    ON UPDATE NO ACTION
    ON DELETE CASCADE;

ALTER TABLE closet.wears
    ADD FOREIGN KEY (garment_id)
    REFERENCES closet.garments (id)
    ON UPDATE NO ACTION
    ON DELETE CASCADE;

ALTER TABLE schedule.events
    ADD FOREIGN KEY (kakao_place_id)
    REFERENCES schedule.places (kakao_place_id)
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;

ALTER TABLE account.profiles
    ADD FOREIGN KEY (user_id)
    REFERENCES account.users (id)
    ON UPDATE NO ACTION
    ON DELETE CASCADE;

ALTER TABLE account.user_identities
    ADD FOREIGN KEY (user_id)
    REFERENCES account.users (id)
    ON UPDATE NO ACTION
    ON DELETE CASCADE;


