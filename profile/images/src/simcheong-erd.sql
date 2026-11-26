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
COMMENT ON TABLE account.profiles IS '회원정보 : 온보딩에서 받고 말로 고칠 수 있음(PUT /api/v1/me/profile). 사용자당 0..1줄이고 users.id를 그대로 키로 씀(식별 관계)';
COMMENT ON COLUMN account.profiles.user_id IS '회원 ID : users.id를 그대로 키로 씀(1:0..1)';
COMMENT ON COLUMN account.profiles."name" IS '이름';
COMMENT ON COLUMN account.profiles.birth_date IS '생년월일';
COMMENT ON COLUMN account.profiles.gender IS '성별';
COMMENT ON COLUMN account.profiles.job IS '직업';
COMMENT ON COLUMN account.profiles.height_cm IS '키(cm)';
COMMENT ON COLUMN account.profiles.weight_kg IS '몸무게(kg)';
COMMENT ON COLUMN account.profiles.agent_name IS '에이전트 이름 : 온보딩에서 사용자가 지은 에이전트 이름(부르면 반응). 값이 있으면 온보딩을 마친 것으로 봄(AccountStore.onboarded)';
COMMENT ON COLUMN account.profiles.created_at IS '만든 시각';
COMMENT ON COLUMN account.profiles.updated_at IS '고친 시각';
COMMENT ON COLUMN account.profiles.call_name IS '호칭 : 에이전트가 사용자를 부르는 말. 예: 진행 님. null이면 따로 부르지 않음';
COMMENT ON COLUMN account.profiles.speech_rate IS '읽어 주는 말 빠르기(TTS) : 앱 TTS(flutter_tts) 빠르기 값, 0.5가 폰 보통 빠르기. null이면 앱 기본값 0.42. 서버 목소리도 이 값 ÷ 0.42배로 맞춤. 앱은 0.3~0.6, gateway는 0.1~1.0만 받음';

COMMENT ON TABLE account.push_tokens IS '푸시 토큰 : 사용자 한 명에 폰 여러 대(1:N). 같은 토큰이 다시 오면 줄을 새로 만들지 않고 user_id·platform·시각만 바꿈(다른 계정으로 로그인한 폰 포함)';
COMMENT ON COLUMN account.push_tokens.id IS 'ID : GENERATED ALWAYS AS IDENTITY(DB가 1씩 늘려 만듦)';
COMMENT ON COLUMN account.push_tokens.user_id IS '회원 ID';
COMMENT ON COLUMN account.push_tokens.token IS '푸시 토큰';
COMMENT ON COLUMN account.push_tokens.platform IS '플랫폼';
COMMENT ON COLUMN account.push_tokens.last_seen_at IS '마지막 등록 시각 : 앱이 PUT /api/v1/me/push-token으로 토큰을 보낼 때마다 now(). 오래된 토큰을 거르는 기준(지금 코드에서는 updated_at과 같은 값)';
COMMENT ON COLUMN account.push_tokens.created_at IS '만든 시각';
COMMENT ON COLUMN account.push_tokens.updated_at IS '고친 시각';

COMMENT ON TABLE account.refresh_tokens IS '갱신 토큰 : 30일. 갱신할 때마다 새로 발급하고 쓴 것은 revoked_at을 채움';
COMMENT ON COLUMN account.refresh_tokens.id IS 'ID : GENERATED ALWAYS AS IDENTITY(DB가 1씩 늘려 만듦)';
COMMENT ON COLUMN account.refresh_tokens.user_id IS '회원 ID';
COMMENT ON COLUMN account.refresh_tokens.token_hash IS '토큰 해시 : 토큰 원문 대신 SHA-256 hex';
COMMENT ON COLUMN account.refresh_tokens.expires_at IS '만료 시각';
COMMENT ON COLUMN account.refresh_tokens.revoked_at IS '폐기 시각';
COMMENT ON COLUMN account.refresh_tokens.created_at IS '만든 시각';
COMMENT ON COLUMN account.refresh_tokens.updated_at IS '고친 시각';

COMMENT ON TABLE account.user_identities IS '로그인 수단 : 로그인 수단 (issuer, subject)마다 한 줄. 계정을 처음 만들 때 함께 만듦(1:1..N). 지금 코드는 계정마다 한 줄만 만듦';
COMMENT ON COLUMN account.user_identities.id IS 'ID : GENERATED ALWAYS AS IDENTITY(DB가 1씩 늘려 만듦)';
COMMENT ON COLUMN account.user_identities.user_id IS '회원 ID';
COMMENT ON COLUMN account.user_identities.issuer IS '발급처 : firebase(Apple·구글) | dev';
COMMENT ON COLUMN account.user_identities.subject IS '로그인 식별값 : Firebase uid 또는 개발용 로그인의 deviceId';
COMMENT ON COLUMN account.user_identities.sign_in_provider IS '마지막 로그인 방법 : 로그인할 때마다 덮어씀(apple·google·dev, Firebase sign_in_provider에서 옴). 갱신 토큰 때 JWT provider 클레임은 updated_at이 가장 최근인 줄 값';
COMMENT ON COLUMN account.user_identities.created_at IS '만든 시각';
COMMENT ON COLUMN account.user_identities.updated_at IS '고친 시각';

COMMENT ON TABLE account.users IS '회원';
COMMENT ON COLUMN account.users.id IS 'ID : 처음 로그인할 때 gateway가 UUID.randomUUID()로 만듦(AccountStore). JWT sub이고 다른 스키마의 user_id와 같은 값. DB 기본값 gen_random_uuid()는 id 없이 넣을 때의 예비값이고, 운영 코드는 늘 id를 직접 넣음';
COMMENT ON COLUMN account.users.last_login_at IS '마지막 로그인';
COMMENT ON COLUMN account.users.created_at IS '만든 시각';
COMMENT ON COLUMN account.users.updated_at IS '고친 시각';

COMMENT ON TABLE closet.garment_defects IS '옷 얼룩·찢어짐 : 옷을 다시 기록(closet_save)할 때마다 그 옷의 줄을 지우고 새로 넣음(이력 아님). kind는 지금 stain·tear만 들어옴(값 CHECK 없음)';
COMMENT ON COLUMN closet.garment_defects.id IS 'ID : GENERATED ALWAYS AS IDENTITY(DB가 1씩 늘려 만듦)';
COMMENT ON COLUMN closet.garment_defects.garment_id IS '옷 ID';
COMMENT ON COLUMN closet.garment_defects.kind IS '종류';
COMMENT ON COLUMN closet.garment_defects."location" IS '위치 : 사진 속 옷 박스를 기준으로 한 대략 위치(옷·몸·등·옆 + 위치)';
COMMENT ON COLUMN closet.garment_defects.confidence IS '결함 모델 확신도 : mcp-clothes-state 결함 모델(YOLO) 점수. checked_by=model이면 0.5 이상. gpt면 모델이 애매했던 0.2~0.5 자리를 GPT가 결함으로 확인한 것이고 kind는 GPT 답. GPT 확신도는 저장하지 않음';
COMMENT ON COLUMN closet.garment_defects.checked_by IS '판단 주체';
COMMENT ON COLUMN closet.garment_defects.created_at IS '만든 시각 : 그 상태를 기록한 시각(처음 발견한 시각 아님)';

COMMENT ON TABLE closet.garments IS '옷';
COMMENT ON COLUMN closet.garments.id IS 'ID : "c_" + SecureRandom 9바이트를 URL용 Base64(패딩 없음)로 바꾼 12글자(Ids.garmentId). MCP 도구의 garmentId';
COMMENT ON COLUMN closet.garments.user_id IS '회원 ID : account.users.id와 같은 값(= JWT sub). 스키마가 달라 FK 없음';
COMMENT ON COLUMN closet.garments.category IS '큰 분류 : 상의(top)·하의(bottom)·겉옷(outer)·원피스(dress)·신발(shoes)·기타(other) 6가지. 세부 이름(예: 니트)은 name';
COMMENT ON COLUMN closet.garments."name" IS '이름';
COMMENT ON COLUMN closet.garments.color_name IS '색 이름 : 색 이름·색 계열·밝기는 mcp-clothes-state가 한 번에 정함(GPT는 색을 정하지 않음). 이름이 계열·밝기에서 하나로 정해지지 않음(예: 연분홍 = pink·red)';
COMMENT ON COLUMN closet.garments.color_family IS '색 계열';
COMMENT ON COLUMN closet.garments.tone IS '밝기';
COMMENT ON COLUMN closet.garments.formality IS '격식';
COMMENT ON COLUMN closet.garments.embedding IS '글 벡터 vector(384) : pgvector vector(384) 칼럼. ERD Designer에 vector 타입이 없어 real[]로 보임';
COMMENT ON COLUMN closet.garments.first_seen_at IS '처음 기록한 시각 : 옷 확인을 마치며 고른 옷을 옷장에 기록(closet_save)한 시각. 카메라로 비출 때마다 바뀌지 않음';
COMMENT ON COLUMN closet.garments.last_seen_at IS '마지막 기록 시각 : 같은 옷을 다시 기록(closet_save)한 마지막 시각';
COMMENT ON COLUMN closet.garments.created_at IS '만든 시각';
COMMENT ON COLUMN closet.garments.updated_at IS '고친 시각';
COMMENT ON COLUMN closet.garments.image_embedding IS '사진 벡터 vector(768) : pgvector vector(768) 칼럼. ERD Designer에 vector 타입이 없어 real[]로 보임. image_model과 함께 비거나 함께 채워짐(garments_image_model_check)';
COMMENT ON COLUMN closet.garments.image_model IS '사진 벡터 모델';
COMMENT ON COLUMN closet.garments.image_count IS '평균에 넣은 사진 수 : 사진 벡터 평균의 가중치. closet.image.max-count(기본 10)에서 멈추고 그 뒤 새 사진 비중은 1/10. 사진 벡터 없이 같은 옷으로 합칠 때는 늘지 않음';
COMMENT ON COLUMN closet.garments.thumbnail IS '옷 부분 작은 사진 : 같은 옷 확인용. agent가 옷 부분만 잘라 긴 변 256px·48KB 이하 JPEG로 보내고 mcp-closet도 48KB(49,152바이트)를 넘으면 버림. DB CHECK는 64KB';
COMMENT ON COLUMN closet.garments.thumbnail_at IS '작은 사진 저장 시각';
COMMENT ON COLUMN closet.garments.pattern IS '무늬';
COMMENT ON COLUMN closet.garments.pattern_checked_by IS '무늬 판단 주체';
COMMENT ON COLUMN closet.garments.pattern_guess IS '무늬 짐작';
COMMENT ON COLUMN closet.garments.material IS '소재(추정) : 옷 종류로 짐작한 값(니트·가디건이면 니트, 그 밖은 null)';
COMMENT ON COLUMN closet.garments.notes IS '기타 메모 : 지금 코드는 채우지 않음(V4가 옮긴 예전 값만 있을 수 있음)';
COMMENT ON COLUMN closet.garments.sub_color_name IS '보조 색 이름';
COMMENT ON COLUMN closet.garments.sub_color_family IS '보조 색 계열';

COMMENT ON TABLE closet.style_docs IS '코디 지식(RAG) : Spring AI PgVectorStore 표 모양(id, content, metadata, embedding) 그대로. 서버가 뜰 때 md 17개를 조각으로 나눠 맞춰 넣음';
COMMENT ON COLUMN closet.style_docs.id IS 'ID : 출처#조각번호로 만든 이름 기반 UUID(StyleDoc.chunkId, nameUUIDFromBytes). 같은 조각을 다시 넣으면 덮어씀. DB 기본값 gen_random_uuid()는 id 없이 넣을 때의 예비값';
COMMENT ON COLUMN closet.style_docs."content" IS '내용';
COMMENT ON COLUMN closet.style_docs.metadata IS '메타데이터 : 키: source(style_docs/파일.md)·chunkNo(0부터)·embeddingModel·occasion(자리 6가지·any·weather·rain)·minTemp·maxTemp(날씨 문서만). (source, chunkNo)에 식 UNIQUE 인덱스 style_docs_source_chunk_uq. occasion·기온 구간은 문서 단위 값이라 조각마다 되풀이되고, closet_search가 이것으로 거름';
COMMENT ON COLUMN closet.style_docs.embedding IS '글 벡터 vector(384) : pgvector vector(384) 칼럼. ERD Designer에 vector 타입이 없어 real[]로 보임. HNSW 인덱스(vector_cosine_ops)는 DDL 끝에 적음';

COMMENT ON TABLE closet.wears IS '입은·입을 날 : 옷 확인을 마치며 고른 옷과 날짜. 오늘 뒤 날짜는 미리 고른 코디(최대 366일 뒤). 입은 횟수·마지막 입은 날은 오늘까지만 셈(worn_on <= 오늘). 날짜가 지나면 입었는지 따로 확인하지 않음';
COMMENT ON COLUMN closet.wears.id IS 'ID : GENERATED ALWAYS AS IDENTITY(DB가 1씩 늘려 만듦)';
COMMENT ON COLUMN closet.wears.garment_id IS '옷 ID';
COMMENT ON COLUMN closet.wears.worn_on IS '입은 날·입을 날';
COMMENT ON COLUMN closet.wears.created_at IS '만든 시각';
COMMENT ON COLUMN closet.wears.updated_at IS '고친 시각';

COMMENT ON TABLE schedule.events IS '일정';
COMMENT ON COLUMN schedule.events.id IS 'ID : "e_" + 임의 글자 12개. 헷갈리는 0·o·1·l을 뺀 소문자·숫자 32가지에서 SecureRandom으로 고름(ScheduleService.newId). MCP 도구의 eventId';
COMMENT ON COLUMN schedule.events.user_id IS '회원 ID : account.users.id와 같은 값(= JWT sub). 스키마가 달라 FK 없음';
COMMENT ON COLUMN schedule.events.title IS '제목';
COMMENT ON COLUMN schedule.events.start_at IS '시작 시각';
COMMENT ON COLUMN schedule.events.place IS '장소(말한 그대로) : 사용자가 말한 장소 그대로. 카카오에서 찾은 장소는 kakao_place_id로만 가리킴';
COMMENT ON COLUMN schedule.events.kakao_place_id IS '카카오 장소 ID : 카카오에서 찾은 장소. 못 찾으면 null';
COMMENT ON COLUMN schedule.events.occasion IS '자리 종류';
COMMENT ON COLUMN schedule.events.occasion_source IS '자리 판단 근거 : title(제목으로 정함) | place(장소 분류로 정함) | default(못 정함)';
COMMENT ON COLUMN schedule.events.notified_at IS '당일 알림 처리 시각 : MorningReminder(매일 아침 8시)가 알림을 켠 오늘 일정에 채움. 8시 뒤에 등록한 오늘 일정은 등록할 때 채움. 다시 처리하지 않게 하는 표시이고 앱·API는 읽지 않음. 폰 알림은 앱이 폰 안에 예약하고 여기 기록하지 않음';
COMMENT ON COLUMN schedule.events.created_at IS '만든 시각';
COMMENT ON COLUMN schedule.events.updated_at IS '고친 시각';
COMMENT ON COLUMN schedule.events.care_reminded_at IS '드라이클리닝 안내 마친 시각 : 격식 일정(mourning·wedding·formal)만. 등록할 때 이미 3일 안쪽이면 등록 순간 채움(1~3일이면 그때 안내를 말하고, 당일이면 말하지 않음). 아니면 CareReminder(매일 아침 8시)가 1~3일 전에 채움. 다시 안내하지 않게 하는 표시';
COMMENT ON COLUMN schedule.events.remind IS '알림 받기 : false면 알림 없음(remind_days_before·remind_time은 null)';
COMMENT ON COLUMN schedule.events.remind_days_before IS '며칠 전 알림 : 며칠 전에 미리 알릴지. null이면 아직 안 정함(전날 + 당일), 0이면 당일만, 1~14(코드에서 검사)';
COMMENT ON COLUMN schedule.events.remind_time IS '미리 알림 시각 : 서울 시각. null이면 아침 8시. remind_days_before가 0이면 당일 알림 시각';

COMMENT ON TABLE schedule.places IS '장소(카카오) : 카카오에서 찾은 장소를 한 번만 저장(V4 정규화). 일정은 kakao_place_id로만 가리킴';
COMMENT ON COLUMN schedule.places.kakao_place_id IS '카카오 장소 ID : 카카오 로컬 장소 ID를 그대로 키로 씀';
COMMENT ON COLUMN schedule.places.place_name IS '장소 이름 : 카카오에 등록된 이름';
COMMENT ON COLUMN schedule.places.category IS '장소 종류 : 카카오 분류의 마지막 마디만. 예: 가정,생활 > 예식장 → 예식장. 일정 자리(occasion)는 저장하지 않는 전체 분류로 정함';
COMMENT ON COLUMN schedule.places.created_at IS '만든 시각';
COMMENT ON COLUMN schedule.places.updated_at IS '고친 시각';


/* 아래는 ERD Designer가 담지 못해 손으로 덧붙였어요(2026-11-26 배포 DB 구조와 같음).
 * - 벡터 칼럼: 위 CREATE TABLE의 REAL[] 세 칸은 배포 DB에서 pgvector 타입이에요.
 *   closet.garments.embedding = public.vector(384), closet.garments.image_embedding = public.vector(768), closet.style_docs.embedding = public.vector(384)
 * - FK 이름: 위 ADD FOREIGN KEY에는 이름이 없어요. 배포 DB의 이름은 .erd 관계 이름과 같아요.
 *   push_tokens_user_id_fkey, user_identities_user_id_fkey, profiles_user_id_fkey, refresh_tokens_user_id_fkey,
 *   garment_defects_garment_id_fkey, wears_garment_fk, events_place_fk
 * - 인덱스 2개: closet V1 마이그레이션 그대로. HNSW 인덱스는 embedding이 vector 타입일 때만 만들 수 있어요. */
CREATE INDEX style_docs_embedding_idx ON closet.style_docs USING hnsw (embedding public.vector_cosine_ops);
CREATE UNIQUE INDEX style_docs_source_chunk_uq ON closet.style_docs (((metadata::jsonb ->> 'source')), ((metadata::jsonb ->> 'chunkNo')));
