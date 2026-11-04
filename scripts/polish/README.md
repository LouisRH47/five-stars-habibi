Polish pass extras (Session 66). Each of Sessions 67 to 71 puts ONE file here with the name
reserved in scripts/polish_hooks.gd (look_extras.gd, world_extras.gd, hud_extras.gd,
phone_extras.gd, screen_extras.gd). It needs `static func attach(world: Node) -> void`, which the
PolishHooks autoload calls once when the game world opens. A missing file is simply skipped.
