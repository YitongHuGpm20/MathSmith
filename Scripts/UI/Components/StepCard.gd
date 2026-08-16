## Presents one draggable solution Step inside the Game Scene Step area.
##
## This UI component stores display text and supports visual drag-and-drop. It
## does not know whether its current position is correct.
extends PanelContainer

#region ========== Signals ==========

signal dragStarted
signal dragCompleted

#endregion

#region ========== References ==========

@onready var stepLabel: Label = $MarginContainer/TextAnchor/StepLabel

#endregion

#region ========== Variables ==========

var stepText: String = ""
var isDragging: bool = false
var interactionLocked: bool = false

#endregion

#region ========== Godot Functions ==========

# Applies any setup data received before this card became ready.
func _ready() -> void:
	UpdateDisplay()

# Creates a full-size card that stays attached to the original mouse grab point.
func _get_drag_data(at_position: Vector2) -> Variant:
	if interactionLocked:
		return null

	var previewRoot := Control.new()
	var previewCard := duplicate()
	previewRoot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	previewCard.stepText = stepText
	previewCard.position = -at_position
	previewCard.custom_minimum_size = size
	previewCard.size = size
	previewCard.mouse_filter = Control.MOUSE_FILTER_IGNORE
	previewCard.modulate = Color(1.05, 1.05, 1.05, 0.96)
	previewRoot.add_child(previewCard)
	set_drag_preview(previewRoot)

	# Hide the source so the card appears physically lifted from the queue.
	isDragging = true
	modulate.a = 0.0
	dragStarted.emit()
	AudioManager.PlayDrag()
	return self

# Restores the source card after the drag succeeds or is cancelled.
func _notification(what: int) -> void:
	if what != NOTIFICATION_DRAG_END or not isDragging:
		return

	# The dragged source reliably knows whether any valid drop target accepted it.
	if is_drag_successful():
		dragCompleted.emit()

	isDragging = false
	modulate.a = 1.0

# Accepts another StepCard from the same visual step area.
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not data is PanelContainer or data.get_parent() != get_parent():
		return false

	# Live reordering can move the dragged source beneath the pointer itself.
	# Accept it as a valid final target without requesting another index change.
	if data == self:
		return true

	# Reorder while hovering above or below this card's midpoint.
	var targetIndex := get_index()

	if at_position.y > size.y * 0.5:
		targetIndex += 1

	get_parent().PreviewCardPosition(data, targetIndex)
	return true

# Moves the dragged card to this card's current list position.
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data.get_parent() != get_parent():
		return

	# Hovering already selected the position; dropping confirms the visual order.
	get_parent().ConfirmCardPosition()
	AudioManager.PlayDrop()

#endregion

#region ========== Functions ==========

# Applies the generated solution text without displaying a redundant order number.
func Setup(displayText: String) -> void:
	stepText = displayText

	# Defer label access when Setup runs before the card's ready lifecycle.
	if not is_node_ready():
		return

	UpdateDisplay()

# Refreshes visual labels from the card's stored setup data.
func UpdateDisplay() -> void:
	stepLabel.text = stepText

# Enables or blocks card dragging after gameplay validation.
func SetInteractionLocked(isLocked: bool) -> void:
	interactionLocked = isLocked
	mouse_default_cursor_shape = (
		Control.CURSOR_ARROW if interactionLocked else Control.CURSOR_POINTING_HAND
	)

#endregion
