# 말랑이의 정복 프로젝트 관리 규범

이 문서는 **말랑이의 정복(Mallang's Conquest)** 저장소의 기본 개발 규범이다.
새 코드와 자산은 이 문서를 따르며, 예외가 필요하면 임시 우회보다 규범을 먼저 수정하고
그 이유를 변경 내역에 남긴다.

- 기준일: 2026-10-14
- 엔진 기준: `project.godot`에 선언된 Godot 4.7, GDScript, 2D
- 렌더러 기준: 모바일 호환성과 iOS 시뮬레이터 테스트를 위해 Compatibility 렌더러부터 사용
  (`project.godot`의 현재 Mobile 설정은 첫 구현 전에 별도 변경)
- 현재 목표: 코어 전투 메카닉 PoC
- 판단 우선순위: 플레이 감각 검증 > 구조의 명료성 > 확장성 > 조기 최적화

## 1. 기본 원칙

1. **기능 단위로 가까이 둔다.** 씬, 스크립트, 전용 자산은 같은 기능 폴더에 둔다.
2. **논리와 표현을 분리한다.** 전투 결과는 화면 노드나 물리 충돌체가 아니라 배열 기반
   시뮬레이션이 결정한다.
3. **씬은 가능한 한 독립적이어야 한다.** 하위 씬은 부모나 형제의 구체적인 경로를
   추측하지 않는다.
4. **소유자가 연결을 조정한다.** 부모가 자식을 초기화하고, 형제 간 통신을 중재한다.
5. **데이터에 Node를 남용하지 않는다.** 화면·입력·엔진 생명주기가 필요하지 않은
   시뮬레이션 객체는 `RefCounted` 또는 `Resource`로 만든다.
6. **Autoload는 기본 선택지가 아니다.** 수명과 책임이 진짜로 전역인 시스템에만 쓴다.
7. **PoC에 필요하지 않은 추상화는 만들지 않는다.** 실제로 두 번째 사용처가 생기기 전까지
   공용화하지 않는다.
8. **전투는 액션에만 집중한다.** 전투 도중 레벨업, 무작위 강화 선택, 장비 교체로 흐름을
   멈추지 않는다.
9. **성장 상태와 전투 상태를 분리한다.** 전투는 시작할 때 확정된 구성의 스냅샷만 받고,
   종료 시 결과만 반환한다.

## 2. 디렉터리 구조

초기 구조는 아래를 기준으로 하되, 빈 폴더를 미리 만들지는 않는다.

```text
res://
├── project.godot
├── docs/                    # `.gdignore`로 Godot 가져오기에서 제외
│   ├── project_guidelines.md
│   └── poc_implementation_plan.md
├── main/
│   ├── main.tscn
│   └── main.gd
├── battle/
│   ├── battle.tscn
│   ├── battle.gd
│   ├── simulation/
│   │   ├── battle_simulation.gd
│   │   ├── battle_state.gd
│   │   └── simulation_event.gd
│   ├── input/
│   │   └── battle_input.gd
│   ├── ai/
│   │   └── enemy_touch_ai.gd
│   ├── rendering/
│   │   └── battle_renderer.gd
│   ├── ui/
│   └── data/
│       ├── battle_config.gd
│       └── *.tres
├── shared/
│   ├── ui/
│   ├── audio/
│   └── shaders/
├── addons/
└── tests/
```

적용 규칙:

- `main/`은 앱의 진입점과 최상위 화면 전환만 담당한다.
- `battle/`은 전투에만 속하는 코드와 자산을 함께 보관한다.
- 특정 기능에서만 쓰는 이미지, 음원, 셰이더는 그 기능 폴더 안에 둔다.
- `shared/`에는 실제로 둘 이상의 기능이 공유하는 것만 둔다. `utils/`, `managers/`,
  `misc/` 같은 의미가 흐린 잡동사니 폴더는 만들지 않는다.
- 외부 플러그인과 범용 서드파티 패키지는 최상위 `addons/`에 둔다. 게임 전용 외부 자산은
  사용되는 기능 가까이에 두고 출처와 라이선스를 함께 기록한다.
- 프로젝트 내부 문서는 `docs/`에서 관리하고 `docs/.gdignore`로 Godot 가져오기 대상에서
  제외한다. 따라서 `docs/` 아래 파일을 `load()`나 `preload()`로 읽어서는 안 된다.
- 전투 밖 성장을 구현하는 시점에는 `meta/` 아래에 `progression/`, `loadout/`, `rewards/`를
  기능별로 추가한다. 코어 전투 PoC 동안에는 이 폴더들을 미리 만들지 않는다.

## 3. 전투 코드의 책임과 의존 방향

```text
BattleInput ──┐
EnemyTouchAI ─┼──> Battle (조정자) ──> BattleSimulation
              │             │                  │
              │             └──> BattleRenderer <── SimulationEvent
              └────────────────> Battle UI
```

### `BattleSimulation`

- `Node`를 상속하지 않는 순수한 전투 규칙 계층으로 만든다.
- 화면 좌표, 노드 경로, 애니메이션, 사운드, 햅틱을 알지 못한다.
- 현재 상태와 다음 상태를 분리해 한 틱의 결과를 일괄 확정한다.
- 입력은 큐로 받아 다음 시뮬레이션 틱에 반영한다.
- 동일한 초기 상태, 입력 기록, 난수 시드로 같은 결과가 재현되어야 한다.
- 생성·증식·충돌·전투 사망·자연 소멸·경계 소멸을 이벤트로 반환한다.

### `BattleRenderer`

- 확정된 상태와 이벤트만 시각화한다.
- 연출이 끝났는지를 전투 판정 조건으로 사용하지 않는다.
- 논리 틱 사이를 보간할 수 있지만 논리 격자를 수정하지 않는다.
- 초기 PoC에서는 `_draw()` 등 단순한 일괄 그리기를 우선한다. 실제 측정 전에는
  셀마다 독립 노드나 `MultiMeshInstance2D` 기반 최적화를 확정하지 않는다.

### `BattleInput`과 `EnemyTouchAI`

- 둘 다 동일한 "빈칸 터치 시도" 명령을 생성한다.
- 플레이어만 또는 AI만 사용할 수 있는 전투 규칙을 만들지 않는다.
- 화면 좌표를 격자 좌표로 바꾸는 책임은 입력 계층에 둔다.
- 유효성 판정과 실제 상태 변경은 시뮬레이션 계층에서 수행한다.

### 설정 데이터

- 틱 속도, 격자 크기, 세포 수명, AI 터치 간격 같은 조정값은 코드에 흩뿌리지 않는다.
- 에디터에서 조정할 데이터 묶음은 커스텀 `Resource`와 `.tres`로 관리한다.
- 실행 중 변하는 전투 상태와 원본 설정 리소스를 분리한다. 공유 리소스를 런타임 상태처럼
  직접 변경하지 않는다.
- 이후 성장 시스템이 추가되면 플레이어의 영구 성장 데이터에서 전투용 불변 스냅샷을
  생성해 전달한다. 전투 도중 원본 성장 데이터나 장착 구성을 직접 읽거나 변경하지 않는다.

## 4. 씬과 노드 규칙

기본 SceneTree는 다음처럼 단순하게 시작한다.

```text
Main
├── World
│   └── Battle
└── GUI
```

- `Main`은 진입점이며 전투 생성, 교체, 재시작을 조정한다.
- 노드는 부모가 사라질 때 함께 사라지는 것이 자연스러운 경우에만 그 부모의 자식으로 둔다.
- 재사용 가능한 하위 씬은 자신의 필수 자식과 자산을 스스로 포함한다.
- 하위 씬이 외부 노드를 찾기 위해 `get_parent()` 연쇄, 절대 `NodePath`, `/root/...`에
  의존하지 않게 한다.
- 부모가 `@export` 속성, 초기화 메서드, `Callable`, 신호 연결을 통해 의존성을 제공한다.
- 자식은 완료되었거나 발생한 사실을 신호로 올리고, 부모는 동작을 시작시키는 메서드를
  호출한다.
- 형제 노드는 서로 직접 찾지 않고 공통 부모가 연결한다.
- 게임 고유의 재사용 가능한 노드 구성은 씬으로, 동작과 데이터 타입은 스크립트로 표현한다.
- 씬에 반드시 필요한 외부 설정이 있다면 `@tool`과 `_get_configuration_warnings()`로
  에디터에서 잘못된 구성을 발견할 수 있게 한다.

## 5. Autoload 사용 기준

PoC 시작 시 Autoload는 **0개**를 기본값으로 한다. 다음 조건을 모두 만족할 때만 추가한다.

1. 여러 씬 전환을 넘어 계속 살아 있어야 한다.
2. 자신의 상태를 스스로 소유하며 다른 시스템의 내부 상태를 침범하지 않는다.
3. 특정 씬의 자식 노드나 `Resource`, `static func`로 해결하는 것보다 명확하다.

Autoload 후보를 추가할 때는 이 문서에 이름, 책임, 수명, 사용처를 기록한다. `GameManager`,
`Global`, `Utils`처럼 책임 범위가 드러나지 않는 이름은 금지한다.

## 6. 명명과 GDScript 스타일

Godot 공식 GDScript 스타일을 기본으로 한다.

| 대상 | 규칙 | 예시 |
| --- | --- | --- |
| 폴더·파일 | `snake_case`, 영문 소문자 | `battle_simulation.gd` |
| `class_name` | `PascalCase` | `class_name BattleSimulation` |
| 노드 이름 | `PascalCase` | `BattleRenderer` |
| 함수·변수 | `snake_case` | `resolve_collisions()` |
| 신호 | 과거형 `snake_case` | `cell_spawned`, `battle_finished` |
| 상수·enum 멤버 | `CONSTANT_CASE` | `MAX_CELL_AGE` |
| enum 이름 | `PascalCase` | `enum CellFaction` |
| 비공개 멤버 | 앞에 `_` | `_next_state` |

추가 규칙:

- UTF-8, LF, 파일 끝 개행, 탭 들여쓰기를 사용한다.
- 한 줄은 100자 이하를 원칙으로 하고 가능하면 80자 안팎으로 유지한다.
- 한 줄에 문장 하나만 쓴다.
- 공개 API와 시뮬레이션 데이터에는 가능한 한 구체적인 타입을 명시한다.
- 숫자나 문자열의 의미를 추측하게 하지 말고 enum, 상수, 이름 있는 타입을 사용한다.
- `class_name`은 여러 파일에서 타입으로 사용할 가치가 있을 때만 선언한다. 모든 스크립트를
  전역 타입으로 등록하지 않는다.
- 선언 순서는 공식 스타일 가이드의 순서를 따른다: 신호, enum, 상수, 정적 변수,
  `@export`, 일반 변수, `@onready`, 생명주기 콜백, 공개 메서드, 비공개 메서드.
- 주석은 코드가 무엇을 하는지 반복하지 않고, 규칙의 이유·불변조건·성능상 제약을 설명한다.

## 7. 자산과 리소스 관리

- Godot이 사용하는 원본 자산은 프로젝트 내부에 둔다.
- 파일 이동과 이름 변경은 참조 갱신을 확인할 수 있도록 Godot 에디터에서 수행하는 것을
  원칙으로 한다.
- 원본 작업 파일이 매우 크거나 게임에서 직접 쓰이지 않으면 별도 보관소를 검토한다.
- 큰 바이너리 자산을 저장소에 넣기 전 Git LFS 적용 여부를 결정한다. 이미 커밋한 뒤
  뒤늦게 도입하지 않는다.
- 외부 자산에는 출처, 제작자, 라이선스, 수정 여부를 기록한다.
- 같은 자산의 `final`, `final_2`, `new` 사본을 만들지 않는다. 버전은 Git으로 관리한다.

## 8. 버전 관리

- 이 프로젝트는 Git을 기준으로 관리한다. 현재 Git 저장소가 아니라면 첫 구현 전에 별도로
  초기화한다.
- Godot 4.1 이상에서 생성되는 `.godot/`과 `*.translation`은 커밋하지 않는다.
- `project.godot`, `.tscn`, `.tres`, `.gd`, `.godot` 밖의 `.uid`, import 설정 파일과 원본
  자산은 프로젝트 재현에 필요하므로 커밋한다.
- `export_presets.cfg`는 Godot 4.1 이상에서 버전 관리할 수 있지만, 실제 비밀키·인증서·개인
  경로가 들어가지 않았는지 커밋 전에 확인한다.
- `.gitattributes`에서 텍스트 파일의 LF 줄바꿈을 유지한다.
- 하나의 변경은 하나의 목적을 갖게 한다. 구조 변경과 게임 규칙 변경을 가능하면 분리한다.
- 씬 파일의 충돌을 줄이기 위해 한 변경에서 불필요한 에디터 재저장을 피한다.
- 엔진 버전 업그레이드는 별도 변경으로 수행하고, 백업 또는 Git 복구 지점을 만든 다음
  전체 씬 열기와 실기 빌드를 확인한다.
- `project.godot`의 렌더러, 화면 방향, 스트레치 같은 기반 설정 변경은 게임 규칙 변경과
  분리하고 iOS 및 Android 호환성을 함께 확인한다.

## 9. 구현 및 검증 절차

기능 하나는 다음 순서로 완성한다.

1. 입력과 기대 결과를 작은 규칙으로 정의한다.
2. 가능한 경우 렌더러 없이 시뮬레이션 규칙부터 구현하고 고정 시드로 검증한다.
3. 필요한 최소 씬과 표현을 연결한다.
4. Godot 에디터에서 파싱 오류와 끊어진 리소스 참조가 없는지 확인한다.
5. 데스크톱에서 플레이한 뒤 실제 iPhone에서 터치 누락, 프레임, 발열, 가독성을 확인한다.
6. 측정된 병목만 최적화한다.

완료 조건:

- 플레이어와 AI가 같은 생성·증식·충돌 규칙을 사용한다.
- 같은 시드와 입력으로 시뮬레이션을 재현할 수 있다.
- 자연 소멸과 전투 사망이 데이터와 연출에서 구분된다.
- 한 틱의 충돌은 동일한 이전 세대 상태를 기준으로 판정된다.
- 새 파일의 위치와 이름이 이 문서의 규칙을 따른다.
- 변경한 씬을 직접 실행해 오류가 없고, 관련 플레이 흐름을 확인했다.

## 10. PoC 단계에서 하지 않을 것

- 셀 하나마다 스크립트가 붙은 독립 노드를 수천 개 만들지 않는다.
- 물리 엔진이나 충돌체를 전투 판정의 진실 원천으로 사용하지 않는다.
- 점령전, 전투 후 보상과 성장 시스템, 최종 아트, 복수 증식 패턴을 코어 재미 검증보다
  먼저 만들지 않는다.
- 전투 중 레벨업이나 무작위 강화 선택 화면을 만들지 않는다.
- 프로파일링 없이 셰이더·MultiMesh·오브젝트 풀을 완성형으로 선행 구현하지 않는다.
- 편의를 이유로 전투 상태를 전역 변수나 Autoload에 쌓지 않는다.

## 11. 전투 밖 성장 시스템의 경계

이 절은 PoC 이후 보상과 성장 시스템을 붙일 때 지켜야 할 구조적 규칙이다.

```text
영구 성장 데이터
      │
      ├──> 전투 전 능력치·스킬 구성 ──> BattleLoadout 스냅샷
      │                                      │
      │                                      v
      └── 전투 후 보상 정산 <── BattleResult <── BattleSimulation
```

- 능력치 배분과 스킬 장착은 메인 화면에서만 변경한다.
- `BattleLoadout`은 전투 시작 시 확정하며 전투가 끝날 때까지 변경하지 않는다.
- `BattleSimulation`은 저장 데이터, 재화, 해금 상태와 메인 화면 노드를 참조하지 않는다.
- `BattleResult`에는 승패와 보상 산정에 필요한 원시 지표만 담는다. 보상 재화 계산과 저장은
  전투 바깥의 보상 시스템이 담당한다.
- 패시브 스킬은 전투 시작 전에 등록된 규칙 수정자 또는 명시적인 시뮬레이션 훅으로
  작동하게 한다. 스킬별 예외 코드를 전투 루프 곳곳에 흩뿌리지 않는다.
- 능동 스킬을 추가하더라도 전투 입력 큐를 통과하는 명령으로 표현하고, 별도의 긴 선택
  화면으로 전투를 중단하지 않는다.
- 성장으로 단순 수치만 계속 누적하기보다 새 능력치 배분, 스킬, 증식 패턴과 외형을
  해금하는 방향을 우선한다.
- 패배 보상을 포함한 반복 진행이 영구적으로 막히지 않아야 하며, 능력치 재분배는 자유롭거나
  비용이 매우 작아야 한다.
- 적 난이도는 플레이어 누적 능력치만 복제해 올리지 않고 전장 조건과 AI 터치 성향으로도
  변주한다.

## 12. 공식 문서 근거

이 규범은 다음 Godot 공식 문서를 바탕으로 프로젝트에 맞게 구체화했다.

- [Project organization](https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html)
- [Scene organization](https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html)
- [When to use scenes versus scripts](https://docs.godotengine.org/en/stable/tutorials/best_practices/scenes_versus_scripts.html)
- [When and how to avoid using nodes for everything](https://docs.godotengine.org/en/stable/tutorials/best_practices/node_alternatives.html)
- [Autoloads versus regular nodes](https://docs.godotengine.org/en/stable/tutorials/best_practices/autoloads_versus_internal_nodes.html)
- [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- [File system](https://docs.godotengine.org/en/stable/tutorials/scripting/filesystem.html)
- [Version control systems](https://docs.godotengine.org/en/stable/tutorials/best_practices/version_control_systems.html)
- [UID changes coming to Godot 4.4](https://godotengine.org/article/uid-changes-coming-to-godot-4-4/)

공식 문서가 선택지를 제시하고 이 문서가 하나를 정한 경우에는 이 프로젝트 규범을 따른다.
엔진 버전이 바뀌거나 실제 구현에서 반복적인 마찰이 확인되면, 코드를 예외투성이로 만들기
전에 이 문서를 갱신한다.
