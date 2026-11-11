[README.md](https://github.com/user-attachments/files/34661049/README.md)
<div align="center">

# 👗 패션 에이전트 · 심청이

**시각장애인을 위한 음성 AI 옷 코디 에이전트**

"설명해 주는 앱은 있었지만, 골라 주는 앱은 없었습니다."

</div>

---

## 어떤 앱인가요?

시각장애인이 아침에 옷을 고를 때 가장 어려운 건 "이 옷이 맞는지, 서로 어울리는지, 얼룩은 없는지"를 혼자 확인하는 일입니다.
**심청이**는 말로 대화하는 AI 에이전트입니다. 오늘 날씨와 일정을 보고 먼저 말로 옷을 추천하고, 사용자가 꺼낸 옷을 카메라에 비추면 알맞은지, 얼룩이나 찢어진 곳은 없는지 알려 줍니다.

- 따로 옷을 등록하지 않아도 됩니다. 평소 옷장 정리 방식은 그대로 두고, 꺼낸 옷을 확인만 합니다.
- 사진 찍기 버튼이 없습니다. 폰이 구도를 소리로 안내하고, 옷이 잘 들어오면 알아서 한 장을 찍습니다.
- 쓸수록 내 옷이 기록되어 나에게 맞는 추천이 됩니다.

## 주요 기능

| 기능 | 설명 |
| --- | --- |
| 🎙️ 음성 온보딩 | 첫 실행 때 말로 이름·키 등 내 정보를 묻고, 에이전트 이름(기본 "심청이")과 호칭을 정합니다. 민감한 정보는 건너뛸 수 있습니다. |
| ☀️ 날씨·일정 맞춤 추천 | 기온, 일교차, 비 소식과 오늘 일정(면접, 결혼식, 운동 등)을 함께 보고 어떤 옷이 좋은지 말로 먼저 추천합니다. |
| 📷 카메라 옷 검사 | 꺼낸 옷을 비추면 종류·색·격식을 보고 오늘 날씨와 자리에 맞는지 판단합니다. 얼룩·찢어짐·보풀을 찾아 "빨래하기·다른 옷으로 바꾸기·수선하기"처럼 할 일 중심으로 안내합니다. 두 벌을 나란히 비추면 "왼쪽 흰 셔츠가 더 나아요"처럼 비교해 줍니다. |
| 🙂 얼굴 확인 | 셀카로 화장이 좌우 고르게 되었는지, 이에 무언가 끼지 않았는지 확인합니다. |
| 👨‍👩‍👧 지인에게 물어보기 | "엄마한테 물어봐 줘"라고 하면 사진과 질문을 문자 링크로 보냅니다. 가족은 앱 없이 웹 페이지에서 바로 답합니다. |
| 🗂️ 내 옷장 | 확인한 옷과 입은 날을 기록해 두고, 다음 추천 때 내 옷 중에서 골라 줍니다. |

## 구조

```
Flutter 앱 (iOS · Android)
   │  음성 인식·읽어 주기, ML Kit 구도 안내, 자동 촬영
   ▼
fashion-agent-gateway  ── 로그인(Firebase → JWT), 회원정보, 사용량 제한
   ▼
fashion-agent-agent    ── MCP 서버에서 데이터를 모아 LLM이 한 번에 판단
   ▼
MCP 서버들: weather · schedule · clothes-state · face-check · closet · helper
```

MCP 서버는 데이터만 돌려주고, "이 옷이 오늘 맞는가" 같은 판단은 agent가 맡습니다. 사진은 저장하지 않습니다(지인에게 보내는 사진만 24시간 보관 후 삭제).

## 레포지토리

| 레포 | 역할 | 주요 기술 |
| --- | --- | --- |
| [fashion-agent](https://github.com/fashion-agent-team/fashion-agent) | 모바일 앱, 아키텍처·서비스 간 약속 문서 | Flutter, ML Kit, Firebase Auth |
| [fashion-agent-gateway](https://github.com/fashion-agent-team/fashion-agent-gateway) | API 게이트웨이, 로그인, 회원정보 | Spring Cloud Gateway, Spring Security, PostgreSQL, Redis |
| [fashion-agent-agent](https://github.com/fashion-agent-team/fashion-agent-agent) | 대화와 옷 추천을 이끄는 두뇌 | Spring AI (MCP 클라이언트), OpenAI GPT, Redis |
| [mcp-weather](https://github.com/fashion-agent-team/mcp-weather) | 오늘·날짜별 날씨 데이터 | Spring AI MCP Server, Open-Meteo |
| [mcp-schedule](https://github.com/fashion-agent-team/mcp-schedule) | 일정과 장소·자리 종류 | Spring AI MCP Server, 카카오 로컬 API, FCM |
| [mcp-clothes-state](https://github.com/fashion-agent-team/mcp-clothes-state) | 옷 사진 분석(종류·색·얼룩·찢어짐) | YOLO 파인튜닝, ONNX Runtime |
| [mcp-face-check](https://github.com/fashion-agent-team/mcp-face-check) | 얼굴 확인(화장 대칭, 치아) | ML Kit 윤곽점, 분류 모델(ONNX) |
| [mcp-closet](https://github.com/fashion-agent-team/mcp-closet) | 내 옷장 기록과 검색(RAG) | Spring AI VectorStore, pgvector, e5 임베딩 |
| [mcp-helper](https://github.com/fashion-agent-team/mcp-helper) | 가족·친구에게 확인 요청 | 문자 링크, 답장 웹 페이지, FCM |

공통 버전: Java 21 · Spring Boot 4.0.9 · Spring Cloud 2025.1.4 · Spring AI 2.0.2

## 팀

4팀 **fashion-agent**

| 이름 | GitHub |
| --- | --- |
| 이진행 | [@ehgo508](https://github.com/ehgo508) |
| 박창근 | [@chang0580](https://github.com/chang0580) |
| 정지원 | [@jiwon934](https://github.com/jiwon934) |
