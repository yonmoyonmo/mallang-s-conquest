class_name GameData
extends RefCounted
## Static first-release stage and reward definitions.

const FINAL_RIVAL_INDEX := 4
const STARTING_PATTERNS: Array[int] = [0, 1, 2]
const DEFAULT_DECK: Array[int] = [0, 1, 2, -1]

const STAGES: Array[Dictionary] = [
	{
		"id": "rival_01", "name": "두근", "pattern": 4,
		"board_size": 0, "seed": 2101, "ai_patterns": [0, 1, 4],
		"intro": "규칙적인 박자로 영역을 밀어붙이는 라이벌.",
	},
	{
		"id": "rival_02", "name": "등대", "pattern": 5,
		"board_size": 1, "seed": 2202, "ai_patterns": [0, 2, 5],
		"intro": "안정적인 거점을 여럿 세우는 라이벌.",
	},
	{
		"id": "rival_03", "name": "질주", "pattern": 6,
		"board_size": 2, "seed": 2303, "ai_patterns": [1, 2, 6],
		"intro": "넓은 전장을 빠르게 가로지르는 라이벌.",
	},
	{
		"id": "rival_04", "name": "폭발", "pattern": 3,
		"board_size": 1, "seed": 2404, "ai_patterns": [2, 3, 4],
		"intro": "작은 씨앗을 거대한 혼란으로 키우는 라이벌.",
	},
	{
		"id": "rival_05", "name": "여왕", "pattern": 11,
		"board_size": 2, "seed": 2909, "ai_patterns": [3, 6, 9, 11],
		"intro": "모든 패턴을 시험한 뒤 만나는 최종 라이벌.",
	},
	{
		"id": "rival_06", "name": "돌진", "pattern": 7,
		"board_size": 0, "seed": 2505, "ai_patterns": [0, 4, 7],
		"intro": "빈틈을 발견하면 한꺼번에 파고드는 라이벌.",
	},
	{
		"id": "rival_07", "name": "분열", "pattern": 8,
		"board_size": 1, "seed": 2606, "ai_patterns": [1, 5, 8],
		"intro": "전선을 여러 갈래로 나누는 라이벌.",
	},
	{
		"id": "rival_08", "name": "새싹", "pattern": 9,
		"board_size": 2, "seed": 2707, "ai_patterns": [2, 3, 9],
		"intro": "조용히 심은 씨앗을 오래 키우는 라이벌.",
	},
	{
		"id": "rival_09", "name": "맥동", "pattern": 10,
		"board_size": 1, "seed": 2808, "ai_patterns": [1, 4, 10],
		"intro": "긴 호흡으로 전장을 흔드는 라이벌.",
	},
]


static func stage(index: int) -> Dictionary:
	if index < 0 or index >= STAGES.size():
		return STAGES[0]
	return STAGES[index]


static func rival_id(index: int) -> StringName:
	return StringName(stage(index)["id"])


static func non_final_indices() -> Array[int]:
	var result: Array[int] = []
	for index in range(STAGES.size()):
		if index != FINAL_RIVAL_INDEX:
			result.append(index)
	return result
