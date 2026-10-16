import '../models/news.dart';

// Self-authored practice content. It must never be presented as NHK news.
const demoNews = [
  NewsItem(
    id: 'demo-sakura',
    isDemo: true,
    illustration: 'sakura',
    titleHtml: '<ruby>公園<rt>こうえん</rt></ruby>の<ruby>桜<rt>さくら</rt></ruby>が<ruby>咲<rt>さ</rt></ruby>き<ruby>始<rt>はじ</rt></ruby>めました',
    date: '练习例文',
    assetAudio: 'assets/demo/sakura.wav',
    bodyHtml: '<p><ruby>東京<rt>とうきょう</rt></ruby>の<ruby>公園<rt>こうえん</rt></ruby>で、<ruby>桜<rt>さくら</rt></ruby>の<ruby>花<rt>はな</rt></ruby>が<ruby>咲<rt>さ</rt></ruby>き<ruby>始<rt>はじ</rt></ruby>めました。</p><p><ruby>公園<rt>こうえん</rt></ruby>に<ruby>来<rt>き</rt></ruby>た<ruby>人<rt>ひと</rt></ruby>たちは、<ruby>写真<rt>しゃしん</rt></ruby>を<ruby>撮<rt>と</rt></ruby>ったり、<ruby>散歩<rt>さんぽ</rt></ruby>をしたりしていました。</p>',
  ),
  NewsItem(
    id: 'demo-station',
    isDemo: true,
    illustration: 'station',
    titleHtml: '<ruby>駅<rt>えき</rt></ruby>に<ruby>新<rt>あたら</rt></ruby>しい<ruby>案内<rt>あんない</rt></ruby>のサービスができました',
    date: '练习例文',
    assetAudio: 'assets/demo/station.wav',
    bodyHtml: '<p><ruby>駅<rt>えき</rt></ruby>で、いろいろな<ruby>言葉<rt>ことば</rt></ruby>を<ruby>使<rt>つか</rt></ruby>うことができる<ruby>案内<rt>あんない</rt></ruby>のサービスが<ruby>始<rt>はじ</rt></ruby>まりました。</p><p><ruby>旅行<rt>りょこう</rt></ruby>に<ruby>来<rt>き</rt></ruby>た<ruby>人<rt>ひと</rt></ruby>が、<ruby>電車<rt>でんしゃ</rt></ruby>の<ruby>時間<rt>じかん</rt></ruby>などを<ruby>調<rt>しら</rt></ruby>べることができます。</p>',
  ),
  NewsItem(
    id: 'demo-rain',
    isDemo: true,
    illustration: 'rain',
    titleHtml: '<ruby>雨<rt>あめ</rt></ruby>の<ruby>日<rt>ひ</rt></ruby>は<ruby>道<rt>みち</rt></ruby>を<ruby>歩<rt>ある</rt></ruby>くときに<ruby>気<rt>き</rt></ruby>をつけてください',
    date: '练习例文',
    assetAudio: 'assets/demo/rain.wav',
    bodyHtml: '<p><ruby>雨<rt>あめ</rt></ruby>が<ruby>降<rt>ふ</rt></ruby>ると、<ruby>道<rt>みち</rt></ruby>が<ruby>滑<rt>すべ</rt></ruby>りやすくなります。</p><p><ruby>急<rt>いそ</rt></ruby>がないで、<ruby>足<rt>あし</rt></ruby>の<ruby>下<rt>した</rt></ruby>をよく<ruby>見<rt>み</rt></ruby>て<ruby>歩<rt>ある</rt></ruby>いてください。</p>',
  ),
];
