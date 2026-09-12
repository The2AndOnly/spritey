class_name Editor
extends Control

var selectedSprite: Sprite
var currentView: StringName = &"sprites"

var signals: Array[String] = ["signal1"]

@warning_ignore("unused_signal")
signal changedView(view: StringName)
