#!/usr/bin/env ruby

ROOT = File.expand_path('..', __dir__)

def replace_once!(source, old_text, new_text, label)
  return if source.include?(new_text)
  raise "Cannot find #{label}" unless source.include?(old_text)

  source.sub!(old_text, new_text)
end

index_path = File.join(ROOT, 'index.html')
index_source = File.binread(index_path)

replace_once!(
  index_source,
  "  <div id=\"tooltip\" class=\"map-tooltip\" role=\"tooltip\"></div>\n\n",
  "  <div id=\"tooltip\" class=\"map-tooltip\" role=\"tooltip\"></div>\n\n  <script src=\"assets/mario/library.js\"></script>\n",
  'Mario image library insertion point in index.html'
)

replace_once!(
  index_source,
  "  for (const character of marioData.characters) {\n    character.collectionSection = sectionByCharacter.get(character.id);",
  "  for (const character of marioData.characters) {\n    character.image = marioImageFor(character.id);\n    character.collectionSection = sectionByCharacter.get(character.id);",
  'Mario character metadata in index.html'
)

File.binwrite(index_path, index_source)

big_star_path = File.join(ROOT, 'big-star-preview.html')
big_star_source = File.binread(big_star_path)

replace_once!(
  big_star_source,
  '</style></head><body>',
  '</style><script src="assets/mario/library.js"></script></head><body>',
  'Mario image library insertion point in big-star-preview.html'
)

if (embedded_start = big_star_source.index('var HERO_IMAGES='))
  embedded_end = big_star_source.index(';</script>', embedded_start)
  raise 'Cannot find the end of the embedded HERO_IMAGES block' unless embedded_end

  big_star_source.slice!(embedded_start, embedded_end + 1 - embedded_start)
end

replace_once!(
  big_star_source,
  "function imageFor(id){return HERO_IMAGES[id]||''}",
  'function imageFor(id){return marioImageFor(id)}',
  'shared image lookup in big-star-preview.html'
)

replace_once!(
  big_star_source,
  "characters.forEach(function(c){byId[c.id]=c;c.collectionSection=sectionByCharacter[c.id];",
  "characters.forEach(function(c){byId[c.id]=c;c.image=imageFor(c.id);c.collectionSection=sectionByCharacter[c.id];",
  'Mario character metadata in big-star-preview.html'
)

big_star_source.gsub!(
  /alt="'\+esc\(c\.display\)\+'"(?! onerror=)/,
  'alt="\'+esc(c.display)+\'" onerror="marioImageFallback(this)"'
)
big_star_source.gsub!(
  /alt="'\+esc\(hero\.display\)\+'"(?! onerror=)/,
  'alt="\'+esc(hero.display)+\'" onerror="marioImageFallback(this)"'
)

File.binwrite(big_star_path, big_star_source)

puts 'Connected both Mario games to assets/mario/library.js'
