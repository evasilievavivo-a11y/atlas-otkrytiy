(function (global) {
  const images = Object.freeze({
  "mario": "assets/mario/mario.png",
  "luigi": "assets/mario/luigi.png",
  "peach": "assets/mario/peach.png",
  "daisy": "assets/mario/daisy.png",
  "rosalina": "assets/mario/rosalina.png",
  "pauline": "assets/mario/pauline.png",
  "toad": "assets/mario/toad.png",
  "toadette": "assets/mario/toadette.png",
  "captain-toad": "assets/mario/captain-toad.png",
  "yoshi": "assets/mario/yoshi.png",
  "birdo": "assets/mario/birdo.png",
  "wario": "assets/mario/wario.png",
  "waluigi": "assets/mario/waluigi.png",
  "donkey-kong": "assets/mario/donkey-kong.png",
  "diddy-kong": "assets/mario/diddy-kong.png",
  "bowser": "assets/mario/bowser.png",
  "bowser-jr": "assets/mario/bowser-jr.png",
  "kamek": "assets/mario/kamek.png",
  "nabbit": "assets/mario/nabbit.png",
  "cappy": "assets/mario/cappy.png",
  "baby-mario": "assets/mario/baby-mario.png",
  "baby-luigi": "assets/mario/baby-luigi.png",
  "baby-peach": "assets/mario/baby-peach.png",
  "baby-daisy": "assets/mario/baby-daisy.png",
  "baby-rosalina": "assets/mario/baby-rosalina.png",
  "koopa-troopa": "assets/mario/koopa-troopa.png",
  "dry-bones": "assets/mario/dry-bones.png",
  "shy-guy": "assets/mario/shy-guy.png",
  "goomba": "assets/mario/goomba.png",
  "lakitu": "assets/mario/lakitu.png",
  "king-boo": "assets/mario/king-boo.png",
  "hammer-bro": "assets/mario/hammer-bro.png",
  "monty-mole": "assets/mario/monty-mole.png",
  "wiggler": "assets/mario/wiggler.png",
  "spike": "assets/mario/spike.png",
  "piranha-plant": "assets/mario/piranha-plant.png",
  "pokey": "assets/mario/pokey.png",
  "cheep-cheep": "assets/mario/cheep-cheep.png",
  "cataquack": "assets/mario/cataquack.png",
  "pianta": "assets/mario/pianta.png",
  "larry": "assets/mario/larry.png",
  "morton": "assets/mario/morton.png",
  "wendy": "assets/mario/wendy.png",
  "iggy": "assets/mario/iggy.png",
  "roy": "assets/mario/roy.png",
  "lemmy": "assets/mario/lemmy.png",
  "ludwig": "assets/mario/ludwig.png",
  "boom-boom": "assets/mario/boom-boom.png",
  "pom-pom": "assets/mario/pom-pom.png",
  "king-bob-omb": "assets/mario/king-bob-omb.png",
  "petey-piranha": "assets/mario/petey-piranha.png",
  "gooper-blooper": "assets/mario/gooper-blooper.png",
  "wingo": "assets/mario/wingo.png",
  "madame-broode": "assets/mario/madame-broode.png",
  "topper": "assets/mario/topper.png",
  "hariet": "assets/mario/hariet.png",
  "rango": "assets/mario/rango.png",
  "spewart": "assets/mario/spewart.png",
  "king-kaliente": "assets/mario/king-kaliente.png",
  "ruined-dragon": "assets/mario/ruined-dragon.png"
});
  const fallback = 'assets/mario/missing.svg';

  global.MARIO_IMAGE_LIBRARY = images;
  global.marioImageFor = function (id) {
    return images[id] || '';
  };
  global.marioImageFallback = function (image) {
    image.onerror = null;
    image.src = fallback;
    image.alt = image.alt ? `${image.alt}: изображение временно недоступно` : 'Изображение временно недоступно';
    image.dataset.imageFallback = 'true';
  };
})(window);
