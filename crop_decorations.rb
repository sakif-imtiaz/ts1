`rm -rf assets/tiny_swords/Deco/cropped`
`cp -a assets/tiny_swords/Deco assets/tiny_swords/Deco/cropped`

`touch assets/tiny_swords/Deco/cropped/decorations.csv`

`for x in  assets/tiny_swords/Deco/cropped/*.png; do
    $(magick $x -trim $x);
    echo $x, $(magick identify -format "%w,%h" $x);
done`

`for x in  assets/tiny_swords/Deco/cropped/*.png; do
    echo $x, $(magick identify -format "%w,%h" $x);
done > assets/tiny_swords/Deco/cropped/decorations.csv`

require 'csv'
require 'json'

Decoration = Struct.new(:cropped_path, :w, :h, :name) do
    def as_json
        {sprite_params: sprite_params, name: name, icon_size: icon_size}
    end

    def icon_size
      {
        h: (h.to_f/64.0).ceil * 64.0,
        w: (w.to_f/64.0).ceil * 64.0,
      }
    end

    def sprite_params
      {
        path: path,
        h: (h.to_f/64.0).ceil * 64.0,
        w: (w.to_f/64.0).ceil * 64.0,
        source_x: 0,
        source_y: 0,
        source_w: (w.to_f/64.0).ceil * 64.0,
        source_h: (h.to_f/64.0).ceil * 64.0,
      }
    end

    def path
      cropped_path.sub("cropped/", "")
    end
end

decoration_names = [:mushroom_small, :mushroom_medium, :mushroom_big,
     :rock_small, :rock_medium, :rock_big,
     :shrub_small, :shrub_medium, :shrub_big,
     :plant_small, :plant_medium,
     :pumpkin_small, :pumpkin_medium,
     :bone_laying, :bone_stuck,
     :sign_danger, :sign_arrow,
     :scarecrow].map(&:to_s)

decorations = CSV.read("assets/tiny_swords/Deco/cropped/decorations.csv").map.with_index do |params, idx|
    Decoration.new(*(params.map(&:strip)), decoration_names[idx])
end

File.open("assets/tiny_swords/Deco/cropped/decorations.json", 'w') do |file|
  file.write JSON.generate(decorations.map(&:as_json))
end 


