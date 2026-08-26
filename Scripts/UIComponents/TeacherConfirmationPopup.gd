## Presents teacher confirmations with the same visual structure as Preview.
##
## This replaces Godot's gray native ConfirmationDialog content surface.
class_name TeacherConfirmationPopup
extends PopupPanel

signal confirmed

#region ========== Variables ==========

@export var popupTitle: String = "Confirm Action"
@export_multiline var message: String = ""
@export var confirmText: String = "Confirm"
@export var dangerous: bool = false
@export var showCancel: bool = true

@onready var titleLabel: Label = %TitleLabel
@onready var messageLabel: Label = %MessageLabel
@onready var cancelButton: Button = %CancelButton
@onready var confirmButton: Button = %ConfirmButton

#endregion

#region ========== Godot Functions ==========

# Builds the configured content and binds the two popup actions.
func _ready() -> void:
	transparent_bg = true
	cancelButton.pressed.connect(hide)
	confirmButton.pressed.connect(ConfirmAction)
	RefreshContent()

#endregion

#region ========== Functions ==========

# Opens the confirmation at its consistent Teacher Tool size.
func Open() -> void:
	RefreshContent()
	popup_centered(Vector2i(680, 290))
	cancelButton.grab_focus()

# Updates reusable confirmation content before opening the popup.
func SetContent(newTitle: String, newMessage: String, newConfirmText: String) -> void:
	popupTitle = newTitle
	message = newMessage
	confirmText = newConfirmText
	if is_node_ready():
		RefreshContent()

# Applies exported content and the correct action hierarchy.
func RefreshContent() -> void:
	titleLabel.text = popupTitle
	messageLabel.text = message
	cancelButton.visible = showCancel
	confirmButton.text = confirmText
	confirmButton.theme_type_variation = &"ButtonDanger" if dangerous else &"ButtonPrimary"

# Closes the popup before notifying the owning Teacher workflow.
func ConfirmAction() -> void:
	hide()
	confirmed.emit()

#endregion
