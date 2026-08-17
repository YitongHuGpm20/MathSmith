## Presents the local prototype password gate for MathSmith Teacher Tools.
##
## This is a convenience barrier for portfolio demonstrations, not secure or
## production-ready authentication. GameManager remains responsible for navigation.
extends Control

#region ========== Constants ==========

const PROTOTYPE_PASSWORD: String = "teacher"

#endregion

#region ========== References ==========

@onready var backButton: Button = %BackButton
@onready var settingsButton: Button = %SettingsButton
@onready var passwordInput: LineEdit = %PasswordInput
@onready var continueButton: Button = %ContinueButton
@onready var feedbackLabel: Label = %FeedbackLabel
@onready var settingsPanel = $SettingsPanel

#endregion

#region ========== Godot Functions ==========

# Connects local access controls and places keyboard focus in the password field.
func _ready() -> void:
	backButton.pressed.connect(GameManager.OpenHome)
	settingsButton.pressed.connect(settingsPanel.Open)
	continueButton.pressed.connect(AttemptAccess)
	passwordInput.text_submitted.connect(_on_password_submitted)
	passwordInput.grab_focus()

#endregion

#region ========== Functions ==========

# Checks the deterministic prototype password without persisting its value.
func AttemptAccess() -> void:
	if passwordInput.text == PROTOTYPE_PASSWORD:
		passwordInput.clear()
		feedbackLabel.text = ""
		GameManager.OpenTeacherDashboard()
		return

	# Keep failure feedback exact and return focus for an immediate retry.
	feedbackLabel.text = tr("Incorrect password.")
	passwordInput.select_all()
	passwordInput.grab_focus()

#endregion

#region ========== Signal Callbacks ==========

# Routes Enter-key submission through the same deterministic access check.
func _on_password_submitted(_submittedText: String) -> void:
	AttemptAccess()

#endregion
