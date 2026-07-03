extends "res://lan_lobby.gd"
## Keeps the ENet connection alive when the lobby changes into lan_party.tscn.

func _ready() -> void:
	super._ready()
	if peer != null and multiplayer.is_server():
		start_button.disabled = false
		status_label.text = "Party connection retained. Host may start another co-op recon session."

func _is_connected() -> bool:
	# The base MultiplayerAPI may contain an OfflineMultiplayerPeer. Only this ENet peer means a real session exists.
	return peer != null

func _exit_tree() -> void:
	# Intentionally do not close the peer here. LAN sessions persist across the lobby and co-op mission scenes.
	pass
