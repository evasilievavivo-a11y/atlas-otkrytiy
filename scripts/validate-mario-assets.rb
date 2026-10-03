#!/usr/bin/env ruby

require 'digest'
require 'json'
require 'open3'

ROOT = File.expand_path('..', __dir__)
ASSET_DIR = File.join(ROOT, 'assets', 'mario')
MANIFEST_PATH = File.join(ASSET_DIR, 'manifest.json')
LIBRARY_PATH = File.join(ASSET_DIR, 'library.js')

EXPECTED_IDS = %w[
  mario luigi peach daisy rosalina pauline toad toadette captain-toad yoshi
  birdo wario waluigi donkey-kong diddy-kong bowser bowser-jr kamek nabbit cappy
  baby-mario baby-luigi baby-peach baby-daisy baby-rosalina koopa-troopa dry-bones
  shy-guy goomba lakitu king-boo hammer-bro monty-mole wiggler spike piranha-plant
  pokey cheep-cheep cataquack pianta larry morton wendy iggy roy lemmy ludwig
  boom-boom pom-pom king-bob-omb petey-piranha gooper-blooper wingo madame-broode
  topper hariet rango spewart king-kaliente ruined-dragon
].freeze

errors = []
manifest = JSON.parse(File.read(MANIFEST_PATH))
characters = manifest.fetch('characters')
ids = characters.map { |character| character.fetch('id') }

game_source = File.binread(File.join(ROOT, 'index.html'))
game_data_start = game_source.index(';window.MARIO_DATA=')
game_data_end = game_source.index(';</script>', game_data_start)
game_data_json = game_source.byteslice(
  game_data_start + ';window.MARIO_DATA='.bytesize,
  game_data_end - game_data_start - ';window.MARIO_DATA='.bytesize
)
game_ids = JSON.parse(game_data_json).fetch('characters').map { |character| character.fetch('id') }

errors << "Expected 60 manifest entries, found #{characters.length}" unless characters.length == 60
errors << "Duplicate ids: #{ids.tally.select { |_id, count| count > 1 }.keys.join(', ')}" unless ids.uniq.length == ids.length
errors << "Missing ids: #{(EXPECTED_IDS - ids).join(', ')}" unless (EXPECTED_IDS - ids).empty?
errors << "Unexpected ids: #{(ids - EXPECTED_IDS).join(', ')}" unless (ids - EXPECTED_IDS).empty?
errors << "Images missing for game ids: #{(game_ids - ids).join(', ')}" unless (game_ids - ids).empty?
errors << "Manifest ids absent from the game: #{(ids - game_ids).join(', ')}" unless (ids - game_ids).empty?

digests = {}
characters.each do |character|
  id = character.fetch('id')
  file = character.fetch('file')
  path = File.join(ASSET_DIR, file)
  unless File.file?(path)
    errors << "#{id}: missing #{file}"
    next
  end

  signature = File.binread(path, 8)
  errors << "#{id}: #{file} is not a PNG" unless signature == "\x89PNG\r\n\x1a\n".b
  errors << "#{id}: #{file} is empty" if File.size(path).zero?

  output, status = Open3.capture2e('sips', '-g', 'pixelWidth', '-g', 'pixelHeight', path)
  if status.success?
    width = output[/pixelWidth:\s*(\d+)/, 1].to_i
    height = output[/pixelHeight:\s*(\d+)/, 1].to_i
    errors << "#{id}: invalid dimensions #{width}x#{height}" if width < 96 || height < 96
    errors << "#{id}: exceeds 512 px (#{width}x#{height})" if width > 512 || height > 512
  else
    errors << "#{id}: cannot read dimensions"
  end

  digest = Digest::SHA256.file(path).hexdigest
  if digests.key?(digest)
    errors << "#{id}: exact duplicate of #{digests[digest]}"
  else
    digests[digest] = id
  end
end

png_files = Dir.glob(File.join(ASSET_DIR, '*.png')).map { |path| File.basename(path, '.png') }
errors << "Unlisted PNG files: #{(png_files - ids).join(', ')}" unless (png_files - ids).empty?

if File.file?(LIBRARY_PATH)
  library_source = File.read(LIBRARY_PATH)
  library_ids = library_source.scan(/^\s+"([^"]+)": "assets\/mario\/[^"]+",?$/).flatten
  errors << "Image library ids differ from manifest" unless library_ids == ids
  ids.each do |id|
    expected_path = "\"#{id}\": \"assets/mario/#{id}.png\""
    errors << "#{id}: wrong path in library.js" unless library_source.include?(expected_path)
  end
else
  errors << 'Missing assets/mario/library.js'
end

%w[index.html big-star-preview.html].each do |html_name|
  html_source = File.read(File.join(ROOT, html_name))
  errors << "#{html_name}: image library is not connected" unless html_source.include?('assets/mario/library.js')
  errors << "#{html_name}: still contains embedded HERO_IMAGES" if html_source.include?('var HERO_IMAGES=')
  errors << "#{html_name}: still contains embedded PNG data" if html_source.include?('data:image/png;base64,')
end

errors << 'index.html: Mario character image paths are not assigned' unless game_source.include?('character.image = marioImageFor(character.id);')
errors << 'index.html: revealed Mario cards do not render character images' unless game_source.include?('mario-avatar ${character.image ? \'has-image\' : \'\'}')
errors << 'index.html: opened collection cards do not render character images' unless game_source.include?('class="mario-tile-picture"')
errors << 'index.html: Leva editor does not render character images' unless game_source.include?('class="editor-character"')

big_star_source = File.read(File.join(ROOT, 'big-star-preview.html'))
errors << 'big-star-preview.html: shared image lookup is not used' unless big_star_source.include?('function imageFor(id){return marioImageFor(id)}')
errors << 'big-star-preview.html: fallback for unavailable images is not connected' unless big_star_source.include?('onerror="marioImageFallback(this)"')

pages_workflow = File.read(File.join(ROOT, '.github', 'workflows', 'publish-pages.yml'))
unless pages_workflow.include?('cp -R development/assets/mario public/development/assets/')
  errors << 'publish-pages.yml: development preview does not include Mario image assets'
end

if errors.empty?
  total_bytes = characters.sum { |character| File.size(File.join(ASSET_DIR, character.fetch('file'))) }
  puts "OK: 60 unique PNG images, #{(total_bytes / 1_048_576.0).round(2)} MiB total"
  exit 0
end

warn errors.map { |error| "ERROR: #{error}" }.join("\n")
exit 1
