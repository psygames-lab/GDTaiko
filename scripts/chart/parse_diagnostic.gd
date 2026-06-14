extends RefCounted
class_name ParseDiagnostic

var line_number: int = 0
var severity: String = ""
var code: String = ""
var message: String = ""


func _init(
	initial_line_number: int = 0,
	initial_severity: String = "",
	initial_code: String = "",
	initial_message: String = ""
) -> void:
	line_number = initial_line_number
	severity = initial_severity
	code = initial_code
	message = initial_message
