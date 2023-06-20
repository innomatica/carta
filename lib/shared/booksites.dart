// url internet archive
const urlInternetArchive = 'https://archive.org/';
const urlInternetArchiveAudio = 'https://archive.org/details/audio';
const urlInternetArchiveRadioShows =
    'https://archive.org/details/radioprograms';
const urlInternetArchiveBBCRadio =
    'https://archive.org/details/folksoundomy_bbcradio';
const urlInternetArchiveRussianAudiobooks =
    'https://archive.org/details/audioboo_ru';
const urlInternetArchiveBlog = 'https://blog.archive.org/';
const urlInternetArchiveDonate = 'https://archive.org/donate/';

// url librivox
const urlLibriVox = 'https://librivox.org';
const urlLibriVoxSearch = 'https://librivox.org/search';
const urlLibriVoxSearchByAuthor =
    'https://librivox.org/search?primary_key=0&search_category=author'
    '&search_page=1&search_form=get_results';
const urlLibriVoxSearchByTitle =
    'https://librivox.org/search?primary_key=0&search_category=title&'
    'search_page=1&search_form=get_results';
const urlLibriVoxSearchByGenre =
    'https://librivox.org/search?primary_key=0&search_category=genre&'
    'search_page=1&search_form=get_results';
const urlLibriVoxSearchByLanguage =
    'https://librivox.org/search?primary_key=0&search_category=language&'
    'search_page=1&search_form=get_results';
const urlLibriVoxDonate = 'https://librivox.org/pages/how-to-donate/';
const urlLibriVoxForum = 'https://librivox.org/forum';

// url legamus
const urlLegamus = 'https://legamus.eu';
const urlLegamusAbout = 'https://legamus.eu/blog/?page_id=33';
const urlLegamusAllRecordings = 'https://legamus.eu/blog/?page_id=161';
const urlLegamusForum = 'https://legamus.eu/forum/index.php';

// web page brower menu
enum BookSite { librivox, internetArchive, legamus }

// book site data
const bookSiteData = {
  BookSite.librivox: {
    'title': 'LibriVox',
    'initialUrl': urlLibriVoxSearchByAuthor,
    'filterString':
        "window.document.getElementsByClassName('book-page').length > 0;",
    'menu': [
      {
        'title': 'Home Page',
        'url': urlLibriVox,
        'value': 'home',
      },
      {
        'title': 'Browse by Author',
        'url': urlLibriVoxSearchByAuthor,
        'value': 'author',
      },
      {
        'title': 'Browse by Book Title',
        'url': urlLibriVoxSearchByTitle,
        'value': 'title',
      },
      {
        'title': 'Browse by Genre',
        'url': urlLibriVoxSearchByGenre,
        'value': 'genre',
      },
      {
        'title': 'Browse by Language',
        'url': urlLibriVoxSearchByLanguage,
        'value': 'language',
      },
      {
        'title': 'Forum',
        'url': urlLibriVoxForum,
        'value': 'forum',
      },
      {
        'title': 'Donate',
        'url': urlLibriVoxDonate,
        'value': 'donate',
      },
      {
        'title': 'Manual URL Entry',
        'url': null,
        'value': 'manual',
      },
    ],
  },
  BookSite.internetArchive: {
    'title': 'Internet Archive',
    'initialUrl': urlInternetArchiveAudio,
    'filterString':
        "window.document.querySelector('meta[property=\"mediatype\"][content=\"audio\"]') != null;",
    'menu': [
      {
        'title': 'Home Page',
        'url': urlInternetArchive,
        'value': 'home',
      },
      {
        'title': 'Audio',
        'url': urlInternetArchiveAudio,
        'value': 'audio',
      },
      {
        'title': 'BBC Radio Shows',
        'url': urlInternetArchiveBBCRadio,
        'value': 'bbc',
      },
      {
        'title': 'Russian Audiobooks',
        'url': urlInternetArchiveRussianAudiobooks,
        'value': 'russian',
      },
      {
        'title': 'Blog',
        'url': urlInternetArchiveBlog,
        'value': 'blog',
      },
      {
        'title': 'Donate',
        'url': urlInternetArchiveDonate,
        'value': 'donate',
      },
      {
        'title': 'Manual URL Entry',
        'url': null,
        'value': 'manual',
      },
    ],
  },
  BookSite.legamus: {
    'title': 'Legamus',
    'initialUrl': urlLegamusAllRecordings,
    'filterString':
        "window.document.querySelector('a[href*=\"listen.legamus.eu\"]') !== null;",
    'menu': [
      {
        'title': 'Home Page',
        'url': urlLegamus,
        'value': 'home',
      },
      {
        'title': 'All Recordings',
        'url': urlLegamusAllRecordings,
        'value': 'all',
      },
      {
        'title': 'About',
        'url': urlLegamusAbout,
        'value': 'about',
      },
      {
        'title': 'Forum',
        'url': urlLegamusForum,
        'value': 'forum',
      }
    ],
  }
};
