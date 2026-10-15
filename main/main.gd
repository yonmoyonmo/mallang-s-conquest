extends Control
## Complete placeholder-driven shell; PNG art hot-swaps through PixelArtSlot.

const BATTLE_SCENE := "res://life_conquest/life_conquest_main.tscn"
@onready var host: MarginContainer = $ScreenHost
var rival := 0
var loadout_return: Callable
var reset_armed := false

func _ready() -> void:
	get_viewport().canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	rival = GameSession.selected_rival
	show_start()

func show_start() -> void:
	clear_screen()
	var layer := Control.new(); layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); host.add_child(layer)
	var bg := art(&"background/start", Vector2(540, 960), "시작 배경"); bg.position = Vector2(-20, -20); layer.add_child(bg)
	var margin := MarginContainer.new(); margin.set_anchors_preset(Control.PRESET_BOTTOM_WIDE); margin.offset_left = 110; margin.offset_top = -150; margin.offset_right = -110; margin.offset_bottom = -70; layer.add_child(margin)
	margin.add_child(button("화면을 눌러 시작", show_menu))

func show_menu() -> void:
	clear_screen(); var page := page("말랑이의 정복")
	page.add_child(art(&"theme/mallang", Vector2(96, 96), "장착 말랑이", StringName(GameSession.mallang_theme)))
	page.add_child(button("라이벌전", show_stages)); page.add_child(button("자유 점령전", show_free)); page.add_child(button("수집함", show_collection)); page.add_child(button("설정 · 크레딧", show_settings))
	page.add_child(small("해금 패턴 %d/12 · 격파 라이벌 %d/9 · 말랑력 %d" % [GameSession.unlocked_patterns.size(), GameSession.cleared_rivals.size(), GameSession.current_energy()]))

func show_stages() -> void:
	clear_screen(); var root := page("라이벌 선택", show_menu); root.add_child(small("8명을 격파하면 중앙의 최종 라이벌이 열린다."))
	var grid := GridContainer.new(); grid.columns = 3; grid.add_theme_constant_override("h_separation", 8); grid.add_theme_constant_override("v_separation", 8); grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER; root.add_child(grid)
	for i in range(GameData.STAGES.size()):
		var data := GameData.stage(i); var card := VBoxContainer.new(); card.custom_minimum_size = Vector2(150, 168)
		card.add_child(art(&"character/rival_card", Vector2(132, 132), String(data.name), StringName(data.id)))
		var locked := i == GameData.FINAL_RIVAL_INDEX and not GameSession.is_final_unlocked()
		var action := button("잠김" if locked else ("완료" if GameSession.is_rival_cleared(i) else "도전"), select_rival.bind(i)); action.disabled = locked; action.custom_minimum_size.y = 42; card.add_child(action); grid.add_child(card)

func select_rival(i: int) -> void:
	rival = i; GameSession.selected_rival = i; show_rival()

func show_rival() -> void:
	clear_screen(); var data := GameData.stage(rival); var root := page(String(data.name), show_stages)
	root.add_child(art(&"character/rival_full", Vector2(300, 400), "라이벌 전체 일러스트", StringName(data.id))); root.add_child(small(String(data.intro)))
	var size := int(data.board_size); root.add_child(small("%s 전장 · %d라운드 · 말랑력 %d" % [LifeConquestConfig.BOARD_SIZE_NAMES[size], LifeConquestConfig.BOARD_ROUNDS[size], GameSession.current_energy()])); root.add_child(small("최초 승리: %s + 라이벌 스킨" % LifeConquestSimulation.pattern_name(int(data.pattern))))
	var row := HBoxContainer.new(); row.alignment = BoxContainer.ALIGNMENT_CENTER; row.add_theme_constant_override("separation", 12); row.add_child(button("편성", open_rival_loadout)); row.add_child(button("도전", start_rival)); root.add_child(row)

func open_rival_loadout() -> void: loadout_return = show_rival; show_loadout()
func open_free_loadout() -> void: loadout_return = show_free; show_loadout()

func show_loadout() -> void:
	clear_screen(); var back := loadout_return if loadout_return.is_valid() else show_menu; var root := page("덱 · 스킨 편성", back); root.add_child(small("누르면 해금한 항목으로 순환한다.")); root.add_child(section("패턴 덱 4칸"))
	var row := HBoxContainer.new(); row.alignment = BoxContainer.ALIGNMENT_CENTER; row.add_theme_constant_override("separation", 6)
	for i in range(4):
		var p := GameSession.deck[i]; var text := "빈 칸" if p < 0 else LifeConquestSimulation.pattern_name(p) + "\n%d" % LifeConquestSimulation.pattern_cost(p); var slot := button(text, cycle_deck.bind(i)); slot.custom_minimum_size = Vector2(120, 90); row.add_child(slot)
	root.add_child(row); root.add_child(section("꾸미기")); root.add_child(button("말랑이 · %s" % theme_name(GameSession.mallang_theme), cycle_mallang)); root.add_child(button("점령 셀 · %s" % theme_name(GameSession.territory_theme), cycle_territory)); root.add_child(button("완료", back))

func cycle_deck(i: int) -> void: GameSession.cycle_deck_slot(i); show_loadout()
func cycle_mallang() -> void: GameSession.cycle_mallang_theme(); show_loadout()
func cycle_territory() -> void: GameSession.cycle_territory_theme(); show_loadout()

func show_free() -> void:
	clear_screen(); var root := page("자유 점령전", show_menu); root.add_child(small("해금한 패턴과 스킨을 원하는 조건으로 시험한다."))
	root.add_child(button("전장 규모 · %s" % LifeConquestConfig.BOARD_SIZE_NAMES[GameSession.free_board_size], cycle_free_board)); root.add_child(button("라운드 말랑력 · %d" % GameSession.free_energy, cycle_free_energy))
	var opponent := "랜덤" if GameSession.free_opponent < 0 else String(GameData.stage(GameSession.free_opponent).name); root.add_child(button("상대 · %s" % opponent, cycle_free_opponent)); root.add_child(button("덱 · 스킨 편성", open_free_loadout)); root.add_child(button("자유 점령전 시작", start_free))

func cycle_free_board() -> void: GameSession.cycle_free_board_size(); show_free()
func cycle_free_energy() -> void: GameSession.cycle_free_energy(); show_free()
func cycle_free_opponent() -> void: GameSession.cycle_free_opponent(); show_free()

func show_collection() -> void:
	clear_screen(); var root := page("수집함", show_menu); root.add_child(section("패턴 도감 · %d/12" % GameSession.unlocked_patterns.size())); var names: Array[String] = []
	for p in range(LifeConquestSimulation.PATTERN_COUNT): names.append(LifeConquestSimulation.pattern_name(p) if p in GameSession.unlocked_patterns else "???")
	root.add_child(small(" · ".join(names))); root.add_child(section("라이벌 앨범 · %d/9" % GameSession.cleared_rivals.size())); names.clear()
	for i in range(GameData.STAGES.size()): names.append(String(GameData.stage(i).name) if GameSession.is_rival_cleared(i) else "???")
	root.add_child(small(" · ".join(names))); root.add_child(section("스킨 · %d세트" % GameSession.unlocked_themes.size())); root.add_child(small(" · ".join(GameSession.unlocked_themes)))

func show_settings() -> void:
	clear_screen(); var root := page("설정 · 크레딧", show_menu); root.add_child(button("음악 · %s" % on_off(GameSession.music_enabled), toggle_music)); root.add_child(button("효과음 · %s" % on_off(GameSession.sound_enabled), toggle_sound)); root.add_child(button("햅틱 · %s" % on_off(GameSession.haptics_enabled), toggle_haptics)); root.add_child(button("진화 속도 · %s" % ["느림", "보통", "빠름"][GameSession.evolution_speed], cycle_speed)); root.add_child(small("버전 0.1.0 · 일회 구매형 · 광고 없음")); root.add_child(button("한 번 더 눌러 초기화" if reset_armed else "정복 기록 초기화", reset_progress))

func toggle_music() -> void: GameSession.music_enabled = not GameSession.music_enabled; save_and_settings()
func toggle_sound() -> void: GameSession.sound_enabled = not GameSession.sound_enabled; save_and_settings()
func toggle_haptics() -> void: GameSession.haptics_enabled = not GameSession.haptics_enabled; save_and_settings()
func cycle_speed() -> void: GameSession.evolution_speed = (GameSession.evolution_speed + 1) % 3; save_and_settings()
func save_and_settings() -> void: GameSession.save_progress(); show_settings()
func reset_progress() -> void:
	if not reset_armed: reset_armed = true; show_settings(); return
	GameSession.reset_progress(); reset_armed = false; show_menu()

func start_rival() -> void:
	if GameSession.prepare_rival_battle(rival): get_tree().change_scene_to_file(BATTLE_SCENE)
func start_free() -> void: GameSession.prepare_free_battle(); get_tree().change_scene_to_file(BATTLE_SCENE)
func clear_screen() -> void:
	for child in host.get_children(): child.queue_free()

func page(title: String, back: Callable = Callable()) -> VBoxContainer:
	var root := VBoxContainer.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.add_theme_constant_override("separation", 14); host.add_child(root); var header := HBoxContainer.new(); header.custom_minimum_size.y = 60
	if back.is_valid(): var b := button("‹", back); b.custom_minimum_size = Vector2(64, 60); header.add_child(b)
	var heading := label(title, 28); heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL; header.add_child(heading); root.add_child(header); return root
func art(id: StringName, size: Vector2, caption: String, variant: StringName = &"default") -> PixelArtSlot: var slot := PixelArtSlot.new(); slot.configure(id, size, caption, variant); slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER; return slot
func button(text: String, action: Callable) -> Button: var b := Button.new(); b.custom_minimum_size = Vector2(0, 60); b.text = text; b.add_theme_font_size_override("font_size", 18); b.pressed.connect(action); return b
func label(text: String, font_size: int) -> Label: var item := Label.new(); item.text = text; item.add_theme_font_size_override("font_size", font_size); item.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; return item
func section(text: String) -> Label: var item := label(text, 21); item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; return item
func small(text: String) -> Label: var item := label(text, 16); item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; return item
func theme_name(id: String) -> String:
	if id == "default": return "기본"
	for data in GameData.STAGES:
		if data.id == id: return String(data.name)
	return id
func on_off(value: bool) -> String: return "켜짐" if value else "꺼짐"
