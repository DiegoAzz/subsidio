extends Control

## QuestUI.gd
## Muestra la Hoja de Ruta / Checklist de Requisitos para el Cierre Financiero.

@onready var quest_list: VBoxContainer = $Panel/VBox/Scroll/QuestList
@onready var close_btn: Button = $Panel/VBox/Header/CloseBtn

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(func(): visible = false)
	GameManager.quest_updated.connect(func(_id, _status): refresh_quests())
	refresh_quests()

func refresh_quests() -> void:
	for child in quest_list.get_children():
		child.queue_free()
		
	for q in GameManager.quests:
		var item: VBoxContainer = VBoxContainer.new()
		var title: Label = Label.new()
		var desc: Label = Label.new()
		var loc: Label = Label.new()
		
		if q["completed"]:
			title.text = "✓ " + q["title"]
			title.modulate = Color(0.3, 1, 0.4)
		else:
			title.text = "○ " + q["title"]
			title.modulate = Color(1, 0.9, 0.4)
			
		desc.text = "   " + q["description"]
		desc.add_theme_font_size_override("font_size", 11)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		loc.text = "   Ubicación: " + q["location"]
		loc.modulate = Color(0.6, 0.8, 1.0)
		loc.add_theme_font_size_override("font_size", 10)
		
		item.add_child(title)
		item.add_child(desc)
		item.add_child(loc)
		item.add_child(HSeparator.new())
		
		quest_list.add_child(item)
