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

## Contributions

One of the things I enjoy most about open source is collaborating with other
people, and I'd love to have more contributions. But, the reality of my life
right now is that my [other main open source project][wren] already has more
activity than I can handle given that I am also [writing a book][book] and have
a wife, kids, pets, and full-time job.

[wren]: https://github.com/munificent/wren
[book]: http://www.craftinginterpreters.com/

So, for my sanity's sake, this project is mostly "read-only". You are welcome to
file bug reports for issues you notice, but I probably won't have the time to
take many pull requests.

I'd be delighted if you used this codebase as a springboard for your own game.
Feel free to fork and make it into your own thing in any way you choose. It uses
a very permissive [MIT license][], so you can do pretty much whatever you want
with it.

Thanks for understanding.

[roguelike]: http://en.wikipedia.org/wiki/Roguelike
[dart]: http://dartlang.org
[splash]: http://i.imgur.com/qWq2UU7.gif
[dungeon]: http://i.imgur.com/0Lrc3dn.gif
[sdk]: https://www.dartlang.org/tools/download.html
[dartium]: https://www.dartlang.org/tools/dartium/
[mit license]: https://github.com/munificent/hauberk/blob/master/COPYRIGHT
