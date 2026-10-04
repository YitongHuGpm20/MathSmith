## Uses browser SpeechRecognition for explicit Web Push-to-Talk input.
##
## Recognition is started only by a player click. No audio or transcript is
## persisted by MathSmith, and unsupported browsers return a normalized error.
extends "res://Scripts/Learning/TutorSpeechInputProvider.gd"

#region ========== Functions ==========

# Identifies the browser-native speech implementation.
func GetProviderId() -> String:
	return "web_speech_recognition"

# Checks browser capability without requesting microphone permission.
func IsSupported() -> bool:
	if not OS.has_feature("web"):
		return false
	return bool(JavaScriptBridge.eval(
		"Boolean(window.SpeechRecognition || window.webkitSpeechRecognition)",
		true
	))

# Starts one non-continuous browser recognition session after a player click.
func StartListening(languageCode: String) -> Dictionary:
	if not IsSupported():
		return BuildState("error", "", "unsupported")
	var browserLanguage := "zh-CN" if languageCode.begins_with("zh") else "en-US"
	var script := """
(() => {
  const Recognition = window.SpeechRecognition || window.webkitSpeechRecognition;
  if (!Recognition) return JSON.stringify({status:'error', transcript:'', errorCode:'unsupported'});
  if (window.__mathsmithSpeechInput?.recognition) {
    try { window.__mathsmithSpeechInput.recognition.abort(); } catch (_) {}
  }
  const state = {status:'listening', transcript:'', errorCode:'', recognition:null};
  const recognition = new Recognition();
  recognition.lang = '__LANGUAGE__';
  recognition.continuous = false;
  recognition.interimResults = false;
  recognition.maxAlternatives = 1;
  state.recognition = recognition;
  recognition.onresult = (event) => {
    state.transcript = event.results[0][0].transcript || '';
    state.status = 'transcript';
  };
  recognition.onerror = (event) => {
    state.errorCode = event.error === 'not-allowed' ? 'permission_denied' : (event.error || 'recognition_failed');
    state.status = 'error';
  };
  recognition.onend = () => {
    if (state.status === 'listening') state.status = 'idle';
  };
  window.__mathsmithSpeechInput = state;
  try { recognition.start(); }
  catch (_) { state.status = 'error'; state.errorCode = 'start_failed'; }
  return JSON.stringify({status:state.status, transcript:state.transcript, errorCode:state.errorCode});
})()
""".replace("__LANGUAGE__", browserLanguage)
	return ParseBrowserState(JavaScriptBridge.eval(script, true))

# Stops browser capture while retaining any final recognition result.
func StopListening() -> Dictionary:
	if not OS.has_feature("web"):
		return BuildState("error", "", "unsupported")
	var script := """
(() => {
  const state = window.__mathsmithSpeechInput;
  if (!state?.recognition) return JSON.stringify({status:'error', transcript:'', errorCode:'not_listening'});
  try { state.recognition.stop(); }
  catch (_) { state.status = 'error'; state.errorCode = 'stop_failed'; }
  if (state.status === 'listening') state.status = 'processing';
  return JSON.stringify({status:state.status, transcript:state.transcript, errorCode:state.errorCode});
})()
"""
	return ParseBrowserState(JavaScriptBridge.eval(script, true))

# Polls asynchronous browser callbacks for transcript or error completion.
func Poll() -> Dictionary:
	if not OS.has_feature("web"):
		return BuildState("error", "", "unsupported")
	var result = JavaScriptBridge.eval("""
(() => {
  const state = window.__mathsmithSpeechInput;
  if (!state) return JSON.stringify({status:'idle', transcript:'', errorCode:''});
  return JSON.stringify({status:state.status, transcript:state.transcript, errorCode:state.errorCode});
})()
""", true)
	return ParseBrowserState(result)

# Normalizes browser JSON without exposing raw JavaScript errors to the player.
func ParseBrowserState(resultValue: Variant) -> Dictionary:
	var parsedResult = JSON.parse_string(String(resultValue))
	if not parsedResult is Dictionary:
		return BuildState("error", "", "invalid_browser_response")
	return BuildState(
		parsedResult.get("status", "error"),
		parsedResult.get("transcript", ""),
		parsedResult.get("errorCode", "")
	)

#endregion
