#!/usr/bin/env ruby

require 'digest'
require 'json'
require 'open3'

ROOT = File.expand_path('..', __dir__)
ASSET_DIR = File.join(ROOT, 'assets', 'mario')
MANIFEST_PATH = File.join(ASSET_DIR, 'manifest.json')

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

if errors.empty?
  total_bytes = characters.sum { |character| File.size(File.join(ASSET_DIR, character.fetch('file'))) }
  puts "OK: 60 unique PNG images, #{(total_bytes / 1_048_576.0).round(2)} MiB total"
  exit 0
end

warn errors.map { |error| "ERROR: #{error}" }.join("\n")
exit 1
