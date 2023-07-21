klass_name = $gtk.argv.split(" ")[2] || "Game"
$my_game = Object.const_get(klass_name).new

def tick args
  $my_game.perform_tick(args)
end
