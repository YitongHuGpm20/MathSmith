## Owns MathSmith's active locale and persisted language preference.
##
## UI text remains authored in English and is translated through Godot's
## TranslationServer. This manager keeps locale selection centralized.
extends Node

#region ========== Signals ==========

signal languageChanged(localeCode: String)

#endregion

#region ========== Constants ==========

const DEFAULT_LOCALE: String = "en"
const SUPPORTED_LOCALES: Array[String] = ["en", "zh_CN"]
const TRANSLATION_CATALOG_PATH: String = "res://Localization/MathSmith.csv"

#endregion

#region ========== Variables ==========

var currentLocale: String = DEFAULT_LOCALE

#endregion

#region ========== Godot Functions ==========

# Applies the saved locale before menu scenes finish presenting their text.
func _ready() -> void:
	LoadTranslationCatalog()
	var settingsData: Dictionary = SaveManager.GetSection("settings")
	ApplyLocale(settingsData.get("language", DEFAULT_LOCALE))

#endregion

#region ========== Functions ==========

# Applies and persists one supported locale.
func SetLanguage(localeCode: String) -> bool:
	if localeCode not in SUPPORTED_LOCALES:
		push_error("Unsupported MathSmith locale: " + localeCode)
		return false

	ApplyLocale(localeCode)
	var settingsData: Dictionary = SaveManager.GetSection("settings")
	settingsData["language"] = currentLocale
	return SaveManager.SetSection("settings", settingsData)

# Registers CSV catalog columns as native Godot Translation resources.
func LoadTranslationCatalog() -> void:
	var catalogFile := FileAccess.open(TRANSLATION_CATALOG_PATH, FileAccess.READ)

	if catalogFile == null:
		push_error("MathSmith translation catalog could not be opened.")
		return

	var header := catalogFile.get_csv_line()
	var translations: Array[Translation] = []

	for localeIndex in range(1, header.size()):
		var translation := Translation.new()
		translation.locale = header[localeIndex]
		translations.append(translation)

	while not catalogFile.eof_reached():
		var catalogRow := catalogFile.get_csv_line()

		if catalogRow.size() < header.size() or catalogRow[0].is_empty():
			continue

		for translationIndex in range(translations.size()):
			translations[translationIndex].add_message(
				catalogRow[0],
				catalogRow[translationIndex + 1].replace("\\n", "\n")
			)

	for translation in translations:
		TranslationServer.add_translation(translation)

# Updates Godot's TranslationServer without modifying unrelated Settings.
func ApplyLocale(localeCode: String) -> void:
	var previousLocale := currentLocale
	currentLocale = localeCode if localeCode in SUPPORTED_LOCALES else DEFAULT_LOCALE
	TranslationServer.set_locale(currentLocale)

	if previousLocale != currentLocale:
		languageChanged.emit(currentLocale)

# Returns the locale used by Settings and future content localization.
func GetCurrentLocale() -> String:
	return currentLocale

#endregion
