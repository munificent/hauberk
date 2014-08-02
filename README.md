![Splash screen][splash]

Hauberk is a [roguelike][], an ASCII-art based procedurally-generated dungeon crawl game. It's written in [Dart] and runs in your browser.

Behold it in all of its glory:

![Dungeon][]

## Running it

To get it up and running locally, you'll need to have the Dart SDK installed.
I use the latest dev channel release of Dart, which you can get from
[here][sdk].

Once you have Dart installed and its `bin/` directory on your `PATH`, then:
 
1. Clone this repo.
2. From the root directory of it, run: `$ pub serve`
3. In your browser, open: `http://localhost:8080`

Pub will automatically compile the game to JavaScript if you hit that URL with
a production browser. Leave pub serve running, and whenever you change the Dart
code, it will notice that and recompile the JS on the fly.

You can iterate even faster and have a much better debugging experience if you
browse to the server using [Dartium][], which comes with the Dart SDK. Just hit
the same URL and it is smart enough to serve the raw Dart code instead of the
compiled JS.

I usually run the game in Dartium, so if you see any bugs in the compiled-to-JS
version please do file an issue.

## Getting involved

I'd love to have more people involved. You're more than welcome to contribute
to Hauberk itself. There's lots to be done, both code and game content
(monsters, items, recipes, areas, etc.)

I also had in mind that this codebase could be used as a springboard for other
games. Feel free to fork Hauberk and make it into your own thing in any way
you choose. It uses a very permissive [MIT license][], so you can do pretty much
whatever you want with it.

[roguelike]: http://en.wikipedia.org/wiki/Roguelike
[dart]: http://dartlang.org
[splash]: http://i.imgur.com/qWq2UU7.gif
[dungeon]: http://i.imgur.com/0Lrc3dn.gif
[sdk]: https://www.dartlang.org/tools/download.html
[dartium]: https://www.dartlang.org/tools/dartium/
[mit license]: https://github.com/munificent/hauberk/blob/master/COPYRIGHT
