class_name Editor
extends Control

var selectedSprite: Sprite
var currentView: StringName = &"sprites"

@warning_ignore("unused_signal")
signal changedView(view: StringName)
