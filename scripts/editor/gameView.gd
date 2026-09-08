class_name GameView
extends SubViewport

func getCoord(x: float, y: float) -> Vector2:
	return (size / 2.0) + Vector2(x, -y)
