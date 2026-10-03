#!/usr/bin/env ruby

require 'fileutils'
require 'json'
require 'open3'
require 'tempfile'
require 'uri'

ROOT = File.expand_path('..', __dir__)
ASSET_DIR = File.join(ROOT, 'assets', 'mario')
EXISTING_DIR = File.expand_path('../../outputs/big-star-assets', ROOT)

CHARACTERS = [
  ['mario', 'Марио', 'Mario', 'mario-web.png'],
  ['luigi', 'Луиджи', 'Luigi', 'luigi-web.png'],
  ['peach', 'Принцесса Пич', 'Princess Peach', 'peach-web.png'],
  ['daisy', 'Принцесса Дейзи', 'Daisy', 'daisy-web.png'],
  ['rosalina', 'Розалина', 'Rosalina', 'rosalina-web.png'],
  ['pauline', 'Полина', 'Pauline', nil],
  ['toad', 'Тоад', 'Toad', 'toad-web.png'],
  ['toadette', 'Тоадетта', 'Toadette', nil],
  ['captain-toad', 'Капитан Тоад', 'Captain Toad', nil],
  ['yoshi', 'Йоши', 'Yoshi', 'yoshi-web.png'],
  ['birdo', 'Бирдо', 'Birdo', nil],
  ['wario', 'Варио', 'Wario', 'wario-web.png'],
  ['waluigi', 'Валуиджи', 'Waluigi', 'waluigi-web.png'],
  ['donkey-kong', 'Донки Конг', 'Donkey Kong', nil],
  ['diddy-kong', 'Дидди Конг', 'Diddy Kong', nil],
  ['bowser', 'Боузер', 'Bowser', 'bowser-web.png'],
  ['bowser-jr', 'Боузер-младший', 'Bowser Jr.', nil],
  ['kamek', 'Камек', 'Kamek', nil],
  ['nabbit', 'Наббит', 'Nabbit', nil],
  ['cappy', 'Кэппи', 'Cappy', nil],
  ['baby-mario', 'Малыш Марио', 'Baby Mario', nil],
  ['baby-luigi', 'Малыш Луиджи', 'Baby Luigi', nil],
  ['baby-peach', 'Малышка Пич', 'Baby Peach', nil],
  ['baby-daisy', 'Малышка Дейзи', 'Baby Daisy', nil],
  ['baby-rosalina', 'Малышка Розалина', 'Baby Rosalina', nil],
  ['koopa-troopa', 'Купа Трупа', 'Koopa Troopa', nil],
  ['dry-bones', 'Драй Боунс', 'Dry Bones', nil],
  ['shy-guy', 'Шай Гай', 'Shy Guy', nil],
  ['goomba', 'Гумба', 'Goomba', nil],
  ['lakitu', 'Лакиту', 'Lakitu', nil],
  ['king-boo', 'Король Бу', 'King Boo', nil],
  ['hammer-bro', 'Хаммер Бро', 'Hammer Bro', nil],
  ['monty-mole', 'Монти Моул', 'Monty Mole', nil],
  ['wiggler', 'Вигглер', 'Wiggler', nil],
  ['spike', 'Спайк', 'Spike', nil],
  ['piranha-plant', 'Растение-пиранья', 'Piranha Plant', nil],
  ['pokey', 'Поки', 'Pokey', nil],
  ['cheep-cheep', 'Чип-Чип', 'Cheep Cheep', nil],
  ['cataquack', 'Катаквак', 'Cataquack', nil],
  ['pianta', 'Пианта', 'Pianta', nil],
  ['larry', 'Ларри', 'Larry', nil],
  ['morton', 'Мортон', 'Morton', nil],
  ['wendy', 'Венди', 'Wendy', nil],
  ['iggy', 'Игги', 'Iggy', nil],
  ['roy', 'Рой', 'Roy', nil],
  ['lemmy', 'Лемми', 'Lemmy', nil],
  ['ludwig', 'Людвиг', 'Ludwig', nil],
  ['boom-boom', 'Бум-Бум', 'Boom Boom', nil],
  ['pom-pom', 'Пом-Пом', 'Pom Pom', nil],
  ['king-bob-omb', 'Король Боб-омб', 'King Bob-omb', nil],
  ['petey-piranha', 'Пити Пиранья', 'Petey Piranha', nil],
  ['gooper-blooper', 'Гупер Блупер', 'Gooper Blooper', nil],
  ['wingo', 'Винго', 'Wingo', nil],
  ['madame-broode', 'Мадам Бруд', 'Madame Broode', nil],
  ['topper', 'Топпер', 'Topper', nil],
  ['hariet', 'Хариет', 'Hariet', nil],
  ['rango', 'Ранго', 'Rango', nil],
  ['spewart', 'Спьюарт', 'Spewart', nil],
  ['king-kaliente', 'Король Калиенте', 'King Kaliente', nil],
  ['ruined-dragon', 'Дракон Руин', 'Ruined Dragon', nil]
].freeze

def run!(*command)
  output, status = Open3.capture2e(*command)
  raise "Command failed: #{command.join(' ')}\n#{output}" unless status.success?
  output
end

def fetch_pages(titles)
  pages = {}
  titles.each_slice(50) do |slice|
    output = run!(
      'curl', '-L', '--fail', '--silent', '--show-error', '--get',
      'https://www.mariowiki.com/api.php',
      '--data-urlencode', 'action=query',
      '--data-urlencode', 'redirects=1',
      '--data-urlencode', 'prop=pageimages',
      '--data-urlencode', 'piprop=original|thumbnail',
      '--data-urlencode', 'pithumbsize=512',
      '--data-urlencode', "titles=#{slice.join('|')}",
      '--data-urlencode', 'format=json'
    )
    JSON.parse(output).fetch('query').fetch('pages').each_value do |page|
      pages[page.fetch('title')] = page
    end
  end
  pages
end

def wiki_page_url(title)
  "https://www.mariowiki.com/#{URI::DEFAULT_PARSER.escape(title.tr(' ', '_'))}"
end

FileUtils.mkdir_p(ASSET_DIR)
pages = fetch_pages(CHARACTERS.map { |character| character[2] })
force = ARGV.include?('--force')

manifest_characters = CHARACTERS.map do |id, display, title, existing_name|
  page = pages.fetch(title) { raise "No Mario Wiki page found for #{title}" }
  source_url = page.dig('thumbnail', 'source') || page.dig('original', 'source')
  raise "No image found for #{title}" unless source_url

  destination = File.join(ASSET_DIR, "#{id}.png")
  unless File.exist?(destination) && !force
    if existing_name
      source_file = File.join(EXISTING_DIR, existing_name)
      raise "Missing existing project asset: #{source_file}" unless File.file?(source_file)
      FileUtils.cp(source_file, destination)
    else
      Tempfile.create(['mario-source', File.extname(URI(source_url).path)]) do |temporary|
        temporary.close
        run!('curl', '-L', '--fail', '--silent', '--show-error', source_url, '-o', temporary.path)
        run!('sips', '-s', 'format', 'png', temporary.path, '--out', destination)
      end
    end
    run!('sips', '-Z', '512', destination)
  end

  {
    'id' => id,
    'display' => display,
    'file' => "#{id}.png",
    'sourcePage' => wiki_page_url(title),
    'sourceImage' => existing_name ? nil : source_url,
    'origin' => existing_name ? 'existing-project-asset' : 'Super Mario Wiki page image'
  }
end

manifest = {
  'schemaVersion' => 1,
  'characterCount' => manifest_characters.length,
  'assetBasePath' => 'assets/mario/',
  'characters' => manifest_characters
}

File.write(File.join(ASSET_DIR, 'manifest.json'), JSON.pretty_generate(manifest) + "\n")
puts "Prepared #{manifest_characters.length} Mario character images in #{ASSET_DIR}"
