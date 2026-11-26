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
    PRIMARY KEY (user_id),
    CONSTRAINT profiles_height_check CHECK (height_cm BETWEEN 50 AND 250),
    CONSTRAINT profiles_weight_check CHECK (weight_kg BETWEEN 10 AND 300),
    CONSTRAINT profiles_birth_check CHECK (birth_date >= DATE '1900-01-01'),
    CONSTRAINT profiles_agent_name_not_blank CHECK (agent_name IS NULL OR length(trim(agent_name)) > 0)
);

CREATE TABLE account.push_tokens (
    id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY,
    user_id UUID NOT NULL,
    token TEXT NOT NULL UNIQUE,
    platform VARCHAR(10) NOT NULL,
    last_seen_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    CONSTRAINT push_tokens_platform_check CHECK (platform IN ('ios', 'android'))
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
    CONSTRAINT user_identities_subject_uq UNIQUE (issuer, subject),
    CONSTRAINT user_identities_issuer_check CHECK (issuer IN ('firebase', 'dev')),
    CONSTRAINT user_identities_provider_check CHECK (sign_in_provider IN ('apple', 'google', 'dev'))
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
    PRIMARY KEY (id),
    CONSTRAINT garment_defects_checked_by_check CHECK (checked_by IN ('model', 'gpt')),
    CONSTRAINT garment_defects_confidence_check CHECK (confidence BETWEEN 0 AND 1)
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
    PRIMARY KEY (id),
    CONSTRAINT garments_category_check CHECK (category IN ('top', 'bottom', 'outer', 'dress', 'shoes', 'other')),
    CONSTRAINT garments_color_family_check CHECK (color_family IN ('black', 'white', 'gray', 'navy', 'beige', 'brown', 'khaki', 'blue', 'red', 'pink', 'orange', 'yellow', 'green', 'purple', 'unknown')),
    CONSTRAINT garments_tone_check CHECK (tone IN ('light', 'mid', 'dark')),
    CONSTRAINT garments_formality_check CHECK (formality IN ('formal', 'smart', 'casual', 'sporty', 'unknown')),
    CONSTRAINT garments_seen_order CHECK (last_seen_at >= first_seen_at),
    CONSTRAINT garments_image_model_check CHECK ((image_embedding IS NULL) = (image_model IS NULL)),
    CONSTRAINT garments_thumbnail_size CHECK (thumbnail IS NULL OR octet_length(thumbnail) <= 65536),
    CONSTRAINT garments_pattern_checked_by_check CHECK (pattern_checked_by IN ('model', 'gpt'))
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
    PRIMARY KEY (id),
    CONSTRAINT events_occasion_check CHECK (occasion IN ('mourning', 'wedding', 'formal', 'business', 'active', 'casual')),
    CONSTRAINT events_occasion_source_check CHECK (occasion_source IN ('title', 'place', 'default')),
    CONSTRAINT events_title_not_blank CHECK (length(trim(title)) > 0)
);

CREATE TABLE schedule.places (
    kakao_place_id VARCHAR(20) NOT NULL,
    place_name VARCHAR(200) NOT NULL,
    category VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (kakao_place_id)
);


/* create indexes. */
CREATE INDEX push_tokens_user_idx ON account.push_tokens USING BTREE (user_id);
CREATE INDEX refresh_tokens_user_idx ON account.refresh_tokens USING BTREE (user_id);
CREATE INDEX user_identities_user_idx ON account.user_identities USING BTREE (user_id);
CREATE INDEX garment_defects_garment_idx ON closet.garment_defects USING BTREE (garment_id);
CREATE INDEX garments_user_category_idx ON closet.garments USING BTREE (user_id, category);
CREATE INDEX garments_user_seen_idx ON closet.garments USING BTREE (user_id, last_seen_at DESC);
CREATE INDEX wears_day_idx ON closet.wears USING BTREE (worn_on DESC);
CREATE INDEX events_user_start_idx ON schedule.events USING BTREE (user_id, start_at);
CREATE INDEX events_start_idx ON schedule.events USING BTREE (start_at);

/* create foreign keys. */
ALTER TABLE account.push_tokens
    ADD FOREIGN KEY (user_id)
    REFERENCES account.users (id)
    ON UPDATE NO ACTION
    ON DELETE CASCADE;

ALTER TABLE account.user_identities
    ADD FOREIGN KEY (user_id)
    REFERENCES account.users (id)
    ON UPDATE NO ACTION
    ON DELETE CASCADE;

ALTER TABLE account.profiles
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

ALTER TABLE account.refresh_tokens
    ADD FOREIGN KEY (user_id)
    REFERENCES account.users (id)
    ON UPDATE NO ACTION
    ON DELETE CASCADE;

ALTER TABLE closet.garment_defects
    ADD FOREIGN KEY (garment_id)
    REFERENCES closet.garments (id)
    ON UPDATE NO ACTION
    ON DELETE CASCADE;


/* create comments. */
COMMENT ON TABLE account.profiles IS '내 정보';
COMMENT ON COLUMN account.profiles.user_id IS '회원 ID';
COMMENT ON COLUMN account.profiles."name" IS '이름';
COMMENT ON COLUMN account.profiles.birth_date IS '생년월일';
COMMENT ON COLUMN account.profiles.gender IS '성별';
COMMENT ON COLUMN account.profiles.job IS '직업';
COMMENT ON COLUMN account.profiles.height_cm IS '키(cm)';
COMMENT ON COLUMN account.profiles.weight_kg IS '몸무게(kg)';
COMMENT ON COLUMN account.profiles.agent_name IS '에이전트 이름';
COMMENT ON COLUMN account.profiles.created_at IS '만든 시각';
COMMENT ON COLUMN account.profiles.updated_at IS '고친 시각';
COMMENT ON COLUMN account.profiles.call_name IS '호칭';
COMMENT ON COLUMN account.profiles.speech_rate IS '말 빠르기';

COMMENT ON TABLE account.push_tokens IS '푸시 토큰';
COMMENT ON COLUMN account.push_tokens.id IS 'ID';
COMMENT ON COLUMN account.push_tokens.user_id IS '회원 ID';
COMMENT ON COLUMN account.push_tokens.token IS '푸시 토큰';
COMMENT ON COLUMN account.push_tokens.platform IS '플랫폼';
COMMENT ON COLUMN account.push_tokens.last_seen_at IS '마지막으로 본 시각';
COMMENT ON COLUMN account.push_tokens.created_at IS '만든 시각';
COMMENT ON COLUMN account.push_tokens.updated_at IS '고친 시각';

COMMENT ON TABLE account.refresh_tokens IS '갱신 토큰';
COMMENT ON COLUMN account.refresh_tokens.id IS 'ID';
COMMENT ON COLUMN account.refresh_tokens.user_id IS '회원 ID';
COMMENT ON COLUMN account.refresh_tokens.token_hash IS '토큰 해시';
COMMENT ON COLUMN account.refresh_tokens.expires_at IS '만료 시각';
COMMENT ON COLUMN account.refresh_tokens.revoked_at IS '폐기 시각';
COMMENT ON COLUMN account.refresh_tokens.created_at IS '만든 시각';
COMMENT ON COLUMN account.refresh_tokens.updated_at IS '고친 시각';

COMMENT ON TABLE account.user_identities IS '로그인 수단';
COMMENT ON COLUMN account.user_identities.id IS 'ID';
COMMENT ON COLUMN account.user_identities.user_id IS '회원 ID';
COMMENT ON COLUMN account.user_identities.issuer IS '발급처';
COMMENT ON COLUMN account.user_identities.subject IS '로그인 식별값';
COMMENT ON COLUMN account.user_identities.sign_in_provider IS '로그인 방법';
COMMENT ON COLUMN account.user_identities.created_at IS '만든 시각';
COMMENT ON COLUMN account.user_identities.updated_at IS '고친 시각';

COMMENT ON TABLE account.users IS '회원';
COMMENT ON COLUMN account.users.id IS 'ID';
COMMENT ON COLUMN account.users.last_login_at IS '마지막 로그인';
COMMENT ON COLUMN account.users.created_at IS '만든 시각';
COMMENT ON COLUMN account.users.updated_at IS '고친 시각';

COMMENT ON TABLE closet.garment_defects IS '옷 상태(얼룩 등)';
COMMENT ON COLUMN closet.garment_defects.id IS 'ID';
COMMENT ON COLUMN closet.garment_defects.garment_id IS '옷 ID';
COMMENT ON COLUMN closet.garment_defects.kind IS '종류';
COMMENT ON COLUMN closet.garment_defects."location" IS '위치';
COMMENT ON COLUMN closet.garment_defects.confidence IS '확신도';
COMMENT ON COLUMN closet.garment_defects.checked_by IS '판단 주체';
COMMENT ON COLUMN closet.garment_defects.created_at IS '만든 시각';

COMMENT ON TABLE closet.garments IS '옷';
COMMENT ON COLUMN closet.garments.id IS 'ID';
COMMENT ON COLUMN closet.garments.user_id IS '회원 ID';
COMMENT ON COLUMN closet.garments.category IS '분류';
COMMENT ON COLUMN closet.garments."name" IS '이름';
COMMENT ON COLUMN closet.garments.color_name IS '색 이름';
COMMENT ON COLUMN closet.garments.color_family IS '색 계열';
COMMENT ON COLUMN closet.garments.tone IS '밝기';
COMMENT ON COLUMN closet.garments.formality IS '격식';
COMMENT ON COLUMN closet.garments.embedding IS '글 벡터 vector(384)';
COMMENT ON COLUMN closet.garments.first_seen_at IS '처음 본 시각';
COMMENT ON COLUMN closet.garments.last_seen_at IS '마지막으로 본 시각';
COMMENT ON COLUMN closet.garments.created_at IS '만든 시각';
COMMENT ON COLUMN closet.garments.updated_at IS '고친 시각';
COMMENT ON COLUMN closet.garments.image_embedding IS '사진 벡터 vector(768)';
COMMENT ON COLUMN closet.garments.image_model IS '사진 벡터 모델';
COMMENT ON COLUMN closet.garments.image_count IS '본 사진 수';
COMMENT ON COLUMN closet.garments.thumbnail IS '옷 부분 작은 사진';
COMMENT ON COLUMN closet.garments.thumbnail_at IS '작은 사진 시각';
COMMENT ON COLUMN closet.garments.pattern IS '무늬';
COMMENT ON COLUMN closet.garments.pattern_checked_by IS '무늬 판단 주체';
COMMENT ON COLUMN closet.garments.pattern_guess IS '무늬 짐작';
COMMENT ON COLUMN closet.garments.material IS '소재';
COMMENT ON COLUMN closet.garments.notes IS '메모';
COMMENT ON COLUMN closet.garments.sub_color_name IS '보조 색 이름';
COMMENT ON COLUMN closet.garments.sub_color_family IS '보조 색 계열';

COMMENT ON TABLE closet.style_docs IS '코디 지식(RAG)';
COMMENT ON COLUMN closet.style_docs.id IS 'ID';
COMMENT ON COLUMN closet.style_docs."content" IS '내용';
COMMENT ON COLUMN closet.style_docs.metadata IS '메타데이터';
COMMENT ON COLUMN closet.style_docs.embedding IS '글 벡터 vector(384)';

COMMENT ON TABLE closet.wears IS '입은 날';
COMMENT ON COLUMN closet.wears.id IS 'ID';
COMMENT ON COLUMN closet.wears.garment_id IS '옷 ID';
COMMENT ON COLUMN closet.wears.worn_on IS '입은 날';
COMMENT ON COLUMN closet.wears.created_at IS '만든 시각';
COMMENT ON COLUMN closet.wears.updated_at IS '고친 시각';

COMMENT ON TABLE schedule.events IS '일정';
COMMENT ON COLUMN schedule.events.id IS 'ID';
COMMENT ON COLUMN schedule.events.user_id IS '회원 ID';
COMMENT ON COLUMN schedule.events.title IS '제목';
COMMENT ON COLUMN schedule.events.start_at IS '시작 시각';
COMMENT ON COLUMN schedule.events.place IS '장소(말한 그대로)';
COMMENT ON COLUMN schedule.events.kakao_place_id IS '카카오 장소 ID';
COMMENT ON COLUMN schedule.events.occasion IS '자리 종류';
COMMENT ON COLUMN schedule.events.occasion_source IS '자리 판단 근거';
COMMENT ON COLUMN schedule.events.notified_at IS '알림 보낸 시각';
COMMENT ON COLUMN schedule.events.created_at IS '만든 시각';
COMMENT ON COLUMN schedule.events.updated_at IS '고친 시각';
COMMENT ON COLUMN schedule.events.care_reminded_at IS '드라이클리닝 안내 시각';
COMMENT ON COLUMN schedule.events.remind IS '알림 받기';
COMMENT ON COLUMN schedule.events.remind_days_before IS '며칠 전 알림';
COMMENT ON COLUMN schedule.events.remind_time IS '알림 시각';

COMMENT ON TABLE schedule.places IS '장소(카카오)';
COMMENT ON COLUMN schedule.places.kakao_place_id IS '카카오 장소 ID';
COMMENT ON COLUMN schedule.places.place_name IS '장소 이름';
COMMENT ON COLUMN schedule.places.category IS '분류';
COMMENT ON COLUMN schedule.places.created_at IS '만든 시각';
COMMENT ON COLUMN schedule.places.updated_at IS '고친 시각';


/* ERD Designer가 그리지 못하는 인덱스 2개. closet V1 마이그레이션 그대로. */
CREATE INDEX style_docs_embedding_idx ON closet.style_docs USING hnsw (embedding public.vector_cosine_ops);
CREATE UNIQUE INDEX style_docs_source_chunk_uq ON closet.style_docs (((metadata::jsonb ->> 'source')), ((metadata::jsonb ->> 'chunkNo')));
