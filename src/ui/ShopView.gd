extends Control

## Shop view UI
## Displays shop items and allows purchasing with scrap
## Reactive component that listens to PlayerStore signals

signal back_button_pressed()

var shop_items: Array[String] = []  # Item IDs available in this shop
var selected_item_id: String = ""

# UI references for reactive updates
var scrap_label: Label = null
var inventory_count_label: Label = null
var item_detail_info_vbox: VBoxContainer = null
var buy_button: Button = null
var buy_button_reason_label: Label = null

func initialize_shop(item_ids: Array[String]):
	"""Initialize shop with specific items BEFORE _ready() is called"""
	shop_items = item_ids.duplicate()
	print("ShopView: Initialized with items: %s" % shop_items)

func _ready():
	# Set anchors to fill the screen
	anchor_right = 1.0
	anchor_bottom = 1.0

	_build_ui()
	_connect_signals()

func _build_ui():
	# Root margin container
	var margin = MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	# Main vertical layout
	var main_vbox = VBoxContainer.new()
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 15)
	margin.add_child(main_vbox)

	# === TITLE AND SCRAP DISPLAY ===
	var title_hbox = HBoxContainer.new()
	title_hbox.custom_minimum_size = Vector2(0, 48)
	main_vbox.add_child(title_hbox)

	var title = Label.new()
	title.text = "SHOP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_hbox.add_child(title)

	scrap_label = Label.new()
	scrap_label.text = "Scrap: %d" % PlayerStore.scrap
	scrap_label.add_theme_font_size_override("font_size", 18)
	scrap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title_hbox.add_child(scrap_label)

	inventory_count_label = Label.new()
	inventory_count_label.text = "Inventory: %d/%d" % [PlayerStore.inventory.size(), ShopEngine.MAX_INVENTORY_SIZE]
	inventory_count_label.add_theme_font_size_override("font_size", 16)
	inventory_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title_hbox.add_child(inventory_count_label)

	# === SHOP CONTENT (3 columns) ===
	var content_hbox = HBoxContainer.new()
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hbox.add_theme_constant_override("separation", 20)
	main_vbox.add_child(content_hbox)

	# Left spacer for centering
	var left_spacer = Control.new()
	left_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_spacer.custom_minimum_size = Vector2(100, 0)
	content_hbox.add_child(left_spacer)

	# Middle: Shop item list
	_build_shop_items_panel(content_hbox)

	# Right: Item detail panel
	_build_item_detail_panel(content_hbox)

	# === BACK BUTTON ===
	var back_button = Button.new()
	back_button.text = "Back to Dungeon"
	back_button.custom_minimum_size = Vector2(200, 40)
	back_button.pressed.connect(_on_back_button_pressed)
	main_vbox.add_child(back_button)

func _build_shop_items_panel(parent: HBoxContainer):
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var label = Label.new()
	label.text = "Items for Sale"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(label)

	var separator = HSeparator.new()
	vbox.add_child(separator)

	# Scrollable item list
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var items_vbox = VBoxContainer.new()
	items_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(items_vbox)

	# Display each shop item
	for item_id in shop_items:
		var item = ItemDatabase.get_item(item_id)
		if not item:
			continue

		var item_button = Button.new()
		item_button.custom_minimum_size = Vector2(0, 60)
		item_button.text = "%s\n%d scrap" % [item.item_name, item.shop_price]
		item_button.pressed.connect(_on_item_selected.bind(item_id))
		items_vbox.add_child(item_button)

	# Select first item by default
	if shop_items.size() > 0:
		_on_item_selected(shop_items[0])

func _build_item_detail_panel(parent: HBoxContainer):
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(vbox)

	var label = Label.new()
	label.text = "Item Details"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(label)

	var separator = HSeparator.new()
	vbox.add_child(separator)

	# Scrollable info section
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	item_detail_info_vbox = VBoxContainer.new()
	item_detail_info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(item_detail_info_vbox)

	# Button container
	var button_container = CenterContainer.new()
	vbox.add_child(button_container)

	var button_vbox = VBoxContainer.new()
	button_vbox.add_theme_constant_override("separation", 5)
	button_container.add_child(button_vbox)

	buy_button = Button.new()
	buy_button.text = "Buy Item"
	buy_button.custom_minimum_size = Vector2(200, 40)
	buy_button.pressed.connect(_on_buy_button_pressed)
	button_vbox.add_child(buy_button)

	buy_button_reason_label = Label.new()
	buy_button_reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	buy_button_reason_label.add_theme_color_override("font_color", Color.ORANGE_RED)
	button_vbox.add_child(buy_button_reason_label)

func _connect_signals():
	PlayerStore.state_changed.connect(_on_player_state_changed)
	PlayerStore.scrap_changed.connect(_on_scrap_changed)

func _on_player_state_changed(property_path: String, _old_value, _new_value):
	if property_path == "inventory":
		_update_inventory_display()
	elif property_path == "scrap":
		_update_scrap_display()

func _on_scrap_changed(_old_value: int, _new_value: int):
	_update_scrap_display()
	_update_buy_button_state()

func _on_item_selected(item_id: String):
	selected_item_id = item_id
	_update_item_detail_display()
	_update_buy_button_state()

func _on_buy_button_pressed():
	if selected_item_id == "":
		return

	var success = ShopEngine.purchase_item(selected_item_id)
	if success:
		print("ShopView: Successfully purchased %s" % selected_item_id)
		# UI will update via signals
		_update_buy_button_state()
	else:
		print("ShopView: Failed to purchase %s" % selected_item_id)

func _on_back_button_pressed():
	back_button_pressed.emit()

func _update_scrap_display():
	if scrap_label:
		scrap_label.text = "Scrap: %d" % PlayerStore.scrap

func _update_inventory_display():
	if inventory_count_label:
		inventory_count_label.text = "Inventory: %d/%d" % [PlayerStore.inventory.size(), ShopEngine.MAX_INVENTORY_SIZE]

func _update_item_detail_display():
	if not item_detail_info_vbox:
		return

	# Clear existing info
	for child in item_detail_info_vbox.get_children():
		child.queue_free()

	if selected_item_id == "":
		return

	var item = ItemDatabase.get_item(selected_item_id)
	if not item:
		return

	# Item name
	var name_label = Label.new()
	name_label.text = item.item_name
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_detail_info_vbox.add_child(name_label)

	# Rarity
	var rarity_label = Label.new()
	rarity_label.text = item.get_rarity_string()
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_detail_info_vbox.add_child(rarity_label)

	# Type
	var type_label = Label.new()
	type_label.text = item.get_item_type_string().capitalize()
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_detail_info_vbox.add_child(type_label)

	# Price
	var price_label = Label.new()
	price_label.text = "Price: %d scrap" % item.shop_price
	price_label.add_theme_font_size_override("font_size", 16)
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_detail_info_vbox.add_child(price_label)

	item_detail_info_vbox.add_child(HSeparator.new())

	# Description
	var desc_label = Label.new()
	desc_label.text = item.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	item_detail_info_vbox.add_child(desc_label)

	# Bonuses
	var bonuses_label = Label.new()
	bonuses_label.text = "Bonuses:\n" + item.get_bonus_description()
	bonuses_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	item_detail_info_vbox.add_child(bonuses_label)

func _update_buy_button_state():
	if not buy_button or selected_item_id == "":
		return

	var check = ShopEngine.can_purchase(selected_item_id)

	if check.can_purchase:
		buy_button.disabled = false
		buy_button_reason_label.text = ""
	else:
		buy_button.disabled = true
		buy_button_reason_label.text = check.reason
