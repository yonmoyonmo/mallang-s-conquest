# 말랑이의 정복 픽셀아트 제작 체크리스트

이 문서는 그림을 제작할 때 바로 확인하는 납품 목록이다. 모든 크기는 **화면 표시 크기가 아닌
1배 원본 캔버스 크기**다. 완성 파일은 PNG로 내보내며 확대본을 별도로 만들지 않는다.

## 1. 가장 먼저 그릴 테스트 세트

아래 6개를 먼저 넣어 화풍, 팔레트와 게임 내 가독성을 확인한다. 이 세트가 확정되기 전에는
나머지 라이벌 자산을 양산하지 않는다.

- [ ] `art/backgrounds/start.png` — `270×480`, 불투명 배경
- [ ] `art/characters/rival_01.png` — `180×240`, 투명 배경
- [ ] `art/themes/mallang/default.png` — `16×16`, 투명 배경
- [ ] `art/themes/territory/default.png` — `16×16`, 반복 타일 또는 무채색 마스크
- [ ] `art/themes/mallang/rival_01.png` — `16×16`, 투명 배경
- [ ] `art/themes/territory/rival_01.png` — `16×16`, 반복 타일 또는 무채색 마스크

## 2. 캐릭터 일러스트

### 라이벌 대표 일러스트 — 총 9장

| 체크 | 파일명 | 해상도 |
| --- | --- | ---: |
| [ ] | `art/characters/rival_01.png` | `180×240` |
| [ ] | `art/characters/rival_02.png` | `180×240` |
| [ ] | `art/characters/rival_03.png` | `180×240` |
| [ ] | `art/characters/rival_04.png` | `180×240` |
| [ ] | `art/characters/rival_05.png` | `180×240` |
| [ ] | `art/characters/rival_06.png` | `180×240` |
| [ ] | `art/characters/rival_07.png` | `180×240` |
| [ ] | `art/characters/rival_08.png` | `180×240` |
| [ ] | `art/characters/rival_09.png` | `180×240` |

제작 조건:

- 캐릭터만 그리고 배경은 투명하게 둔다.
- 발끝까지 포함한 전신 또는 전신에 가까운 구도를 사용한다.
- 카드 초상으로 쓰는 `(54, 12)`부터 `72×72` 영역에 얼굴이 들어와야 한다.
- 대화 초상으로 쓰는 `(42, 8)`부터 `96×96` 영역에 머리와 상반신 특징이 들어와야 한다.
- 캐릭터 바깥쪽에 최소 4px 여백을 남긴다.
- 그림 안에 이름, 대사, 프레임과 UI 장식을 넣지 않는다.

카드 초상 `72×72`, 대화 초상 `96×96`과 잠금 실루엣은 위 원본에서 자동 생성하므로 따로
그리지 않는다.

## 3. 말랑이 스킨

### 살아 있는 말랑이 — 총 10장

모두 `16×16`, 투명 PNG다.

| 체크 | 파일명 | 테마 |
| --- | --- | --- |
| [ ] | `art/themes/mallang/default.png` | 기본 플레이어 |
| [ ] | `art/themes/mallang/rival_01.png` | 라이벌 1 |
| [ ] | `art/themes/mallang/rival_02.png` | 라이벌 2 |
| [ ] | `art/themes/mallang/rival_03.png` | 라이벌 3 |
| [ ] | `art/themes/mallang/rival_04.png` | 라이벌 4 |
| [ ] | `art/themes/mallang/rival_05.png` | 라이벌 5 |
| [ ] | `art/themes/mallang/rival_06.png` | 라이벌 6 |
| [ ] | `art/themes/mallang/rival_07.png` | 라이벌 7 |
| [ ] | `art/themes/mallang/rival_08.png` | 라이벌 8 |
| [ ] | `art/themes/mallang/rival_09.png` | 최종 라이벌 |

제작 조건:

- 실제 형태는 가급적 중앙 `14×14` 안에 두고 바깥 1px을 비운다.
- 작게 보여도 테마를 구분할 수 있는 큰 눈, 귀, 뿔, 머리 장식 같은 특징 하나를 둔다.
- 진영색이 코드에서 곱해지므로 지나치게 고유한 단색보다는 밝고 어두운 면이 구분되는
  무채색 또는 저채도 원본을 권장한다.
- 맥동, 흔들림과 피격 애니메이션은 코드로 처리한다. 프레임 시트는 지금 그리지 않는다.

## 4. 점령 셀 스킨

### 영토 타일 — 총 10장

모두 `16×16` PNG다.

| 체크 | 파일명 | 테마 |
| --- | --- | --- |
| [ ] | `art/themes/territory/default.png` | 기본 플레이어 |
| [ ] | `art/themes/territory/rival_01.png` | 라이벌 1 |
| [ ] | `art/themes/territory/rival_02.png` | 라이벌 2 |
| [ ] | `art/themes/territory/rival_03.png` | 라이벌 3 |
| [ ] | `art/themes/territory/rival_04.png` | 라이벌 4 |
| [ ] | `art/themes/territory/rival_05.png` | 라이벌 5 |
| [ ] | `art/themes/territory/rival_06.png` | 라이벌 6 |
| [ ] | `art/themes/territory/rival_07.png` | 라이벌 7 |
| [ ] | `art/themes/territory/rival_08.png` | 라이벌 8 |
| [ ] | `art/themes/territory/rival_09.png` | 최종 라이벌 |

제작 조건:

- 상하좌우로 반복해도 이음매가 보이지 않게 만든다.
- 진영색을 코드에서 입히므로 무채색 마스크나 저채도 그림을 사용한다.
- 살아 있는 말랑이보다 어둡고 대비가 낮아야 한다.
- 무늬가 셀마다 너무 복잡해지지 않도록 2~3단계 명암만 사용한다.

## 5. 테마 문양

### 보상·스킨 카드용 문양 — 총 10장

모두 `24×24`, 투명 PNG다.

```text
art/themes/emblems/default.png
art/themes/emblems/rival_01.png
art/themes/emblems/rival_02.png
art/themes/emblems/rival_03.png
art/themes/emblems/rival_04.png
art/themes/emblems/rival_05.png
art/themes/emblems/rival_06.png
art/themes/emblems/rival_07.png
art/themes/emblems/rival_08.png
art/themes/emblems/rival_09.png
```

- [ ] 기본 문양 1장
- [ ] 라이벌 문양 9장

각 문양은 라이벌의 대표 패턴이나 외형 특징을 단순화한다. 최대 3색을 권장한다.

## 6. 배경·앱 아이콘

| 체크 | 파일명 | 해상도 | 조건 |
| --- | --- | ---: | --- |
| [ ] | `art/backgrounds/start.png` | `270×480` | 게임 제목 포함, 불투명 |
| [ ] | `art/backgrounds/menu.png` | `270×480` | 메뉴·수집함 공용, 불투명 |
| [ ] | `art/ui/app_icon_256.png` | `256×256` | 글자 없이 단순한 형태 |

배경은 게임의 `540×960` 기준 화면에서 정확히 2배 확대한다. 시작 배경에는 게임 제목을
직접 그린다. 중요한 제목, 얼굴과 문양은 중앙 `220×400` 영역에 두어 긴 화면비의 기기에서도
잘리지 않게 한다. 시작 버튼이 놓이는 원본 하단 약 75px 영역은 복잡한 장식을 피한다.

앱 아이콘은 `256×256` 원본으로 작업하고 스토어용 `1024×1024` 파일은 최근접 보간으로
4배 출력한다. iOS 제출본에는 투명 영역을 남기지 않는다.

## 7. 공용 기능 아이콘

기본 크기는 `24×24`, 투명 PNG다. 작은 HUD에서 자주 쓰는 항목만 `16×16`으로 별도
손질한다. 큰 그림을 자동 축소해 작은 아이콘을 만들지 않는다.

| 체크 | 파일명 | 해상도 | 용도 |
| --- | --- | ---: | --- |
| [ ] | `back_24.png` | `24×24` | 뒤로 |
| [ ] | `home_24.png` | `24×24` | 메인 메뉴 |
| [ ] | `settings_24.png` | `24×24` | 설정 |
| [ ] | `deck_24.png` | `24×24` | 패턴 덱 |
| [ ] | `skin_24.png` | `24×24` | 꾸미기 |
| [ ] | `rotate_24.png` | `24×24` | 패턴 회전 |
| [ ] | `undo_24.png` | `24×24` | 마지막 패턴 배치 취소 |
| [ ] | `flip_24.png` | `24×24` | 패턴 반전 |
| [ ] | `evolve_24.png` | `24×24` | 진화 시작 |
| [ ] | `lock_24.png` | `24×24` | 잠김 |
| [ ] | `unlock_24.png` | `24×24` | 해금 |
| [ ] | `play_24.png` | `24×24` | 도전 시작 |
| [ ] | `retry_24.png` | `24×24` | 재도전 |
| [ ] | `random_24.png` | `24×24` | 랜덤 상대 |
| [ ] | `music_24.png` | `24×24` | 음악 |
| [ ] | `sound_24.png` | `24×24` | 효과음 |
| [ ] | `haptic_24.png` | `24×24` | 진동 |
| [ ] | `speed_24.png` | `24×24` | 진화 속도 |
| [ ] | `info_24.png` | `24×24` | 정보·도움말 |

파일 위치는 모두 `art/ui/icons/`다.

`undo_24.png`는 회전과 혼동되지 않도록 되돌아가는 화살표와 지워지는 셀을 함께 표현한다.
`rotate_24.png`는 **시계방향** 회전임을 한눈에 알 수 있는 굽은 화살표로 그린다. 화살촉을
크게 하고 원형 장식처럼 보이지 않게 한다. `evolve_24.png`는 재생 삼각형 또는 세대가 앞으로
진행되는 모습을 사용하며, 패턴 버튼보다 강한 실루엣으로 그린다. 전투에서는 두 아이콘 모두
`24×24` 원본을 사용한다.

추가로 작은 크기가 필요한 6개:

- [ ] `back_16.png` — `16×16`
- [ ] `rotate_16.png` — `16×16`
- [ ] `flip_16.png` — `16×16`
- [ ] `lock_16.png` — `16×16`
- [ ] `sound_16.png` — `16×16`
- [ ] `speed_16.png` — `16×16`

## 8. UI 프레임 세트

현재는 코드 도형으로 표시할 수 있어 캐릭터와 스킨보다 후순위다. 최종 픽셀 UI를 적용할 때
아래 9패치 원본을 제작한다. 모서리와 테두리는 4px 안에서 완결하고 중앙은 반복 또는 늘이기
가능하게 만든다.

| 체크 | 파일명 | 해상도 |
| --- | --- | ---: |
| [ ] | `art/ui/frames/panel.png` | `24×24` |
| [ ] | `art/ui/frames/button_normal.png` | `24×24` |
| [ ] | `art/ui/frames/button_pressed.png` | `24×24` |
| [ ] | `art/ui/frames/button_disabled.png` | `24×24` |
| [ ] | `art/ui/frames/card_normal.png` | `32×32` |
| [ ] | `art/ui/frames/card_selected.png` | `32×32` |
| [ ] | `art/ui/frames/card_locked.png` | `32×32` |

## 9. 지금은 그리지 않는 것

다음 항목은 게임 데이터나 코드 효과로 생성한다.

- 12종 Game of Life 패턴 아이콘
- 패턴 진화 미리보기
- 전장 격자
- 소형·중형·대형 전용 배경
- 라이벌 카드 초상과 대화 초상
- 잠금 실루엣
- 셀 맥동과 흔들림 프레임
- 배치, 탄생, 사망, 점령과 동률 상쇄 효과

## 10. 공통 납품 규칙

- [ ] PNG, sRGB로 내보낸다.
- [ ] 원본 캔버스 크기를 유지하고 2배·4배 확대본은 저장소에 넣지 않는다.
- [ ] 리사이즈할 때 최근접 보간만 사용한다.
- [ ] 반투명 가장자리와 안티앨리어싱 픽셀을 넣지 않는다.
- [ ] 파일명은 영문 소문자와 밑줄만 사용한다.
- [ ] 같은 테마의 캐릭터, 말랑이, 영토와 문양은 공통 팔레트를 사용한다.
- [ ] 팔레트 원본이 있다면 같은 폴더에 `<theme_id>_palette.png`로 보관한다.
- [ ] 게임에 넣은 뒤 플레이어색과 적색 틴트 양쪽에서 모두 읽히는지 확인한다.

## 11. 총 제작량

| 종류 | 필수 수량 |
| --- | ---: |
| 라이벌 대표 일러스트 | 9 |
| 말랑이 스킨 | 10 |
| 점령 셀 스킨 | 10 |
| 테마 문양 | 10 |
| 배경 | 2 |
| 앱 아이콘 | 1 |
| 24px 기능 아이콘 | 19 |
| 16px 보조 아이콘 | 6 |
| 후순위 UI 프레임 | 7 |

필수 픽셀아트는 UI 프레임을 제외하면 총 **66개 파일**이다. 먼저 1절의 테스트 세트 6개로
게임 안에서 화풍을 검증한 뒤 나머지를 같은 규격으로 제작한다.
