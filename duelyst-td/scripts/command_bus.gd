extends Node

# CommandBus: single dispatch point for player actions.
# Logs every attempt (including rejections) so debug overlay can show them.

signal command_dispatched(record: Dictionary)

const HISTORY_SIZE := 50

var main: Node = null  # set by main.gd._ready()
var history: Array = []  # recent command records (newest last)

func bind_main(m: Node) -> void:
	main = m

func dispatch(cmd: Command) -> bool:
	if main == null:
		push_error("CommandBus.dispatch: main not bound")
		return false
	cmd.execute(main)
	var record: Dictionary = cmd.to_dict()
	record["t"] = Time.get_unix_time_from_system()
	history.append(record)
	if history.size() > HISTORY_SIZE:
		history.pop_front()
	# Forward to RunLog if it's tracking and the command was successful.
	if RunLog.active and cmd.success:
		RunLog.record("command", {
			"type": record["type"],
			"describe": record["describe"],
		})
	command_dispatched.emit(record)
	return cmd.success

func recent(n: int = 20) -> Array:
	var c: int = mini(n, history.size())
	if c <= 0:
		return []
	return history.slice(history.size() - c, history.size())
