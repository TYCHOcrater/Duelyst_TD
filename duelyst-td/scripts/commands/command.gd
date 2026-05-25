class_name Command
extends RefCounted

# Player actions are objects so they can be logged, replayed, validated,
# and (later) sent over the network. Every command MUST set success+reason.

var success: bool = false
var reason: String = ""

func execute(_main: Node) -> bool:
	success = false
	reason = "Command.execute() not implemented"
	return false

func describe() -> String:
	return "Command"

func to_dict() -> Dictionary:
	return {
		"type": _short_name(),
		"describe": describe(),
		"success": success,
		"reason": reason,
	}

func _short_name() -> String:
	var s: Script = get_script()
	if s and s.resource_path != "":
		return s.resource_path.get_file().get_basename()
	return "command"
