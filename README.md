# Karuta-elm

Yomifuda sound player application for competitive Karuta as an example of Elm code with YouTube Iframe API.

## Quickstart

Note: The following description is based on YouTube IFrame API as of the end of Dec, 2017

The key point on how to use YouTube Iframe API is to implement the followings in src/index.js

  - declear a variable to store YouTube player instance

  `var ytPlayer;`

  - define a function which create a YouTube player instance and bind it to 'window.onYouTubeIframeAPIReady'

```
window.onYouTubeIframeAPIReady = function () {
  ytPlayer = new YT.Player("youtube-player", {});
}
```

  - then, you can use the API methods within subscribe functions of Ports

```
app.ports.playVideo.subscribe(function() {
    ytPlayer.playVideo();
});
```

The last example is corresponding to the following Elm Port code

`port playVideo : () -> Cmd msg`

## More detail
By defining callback functions and binding them to the configuration in creating YouTube player instance,
You can receive the YouTube API events in the Elm domain.

In src/index.js

```
window.onYouTubeIframeAPIReady = function () {
    ytPlayer = new YT.Player(playerId, {
        events: {
            'onReady' : onPlayerReady
            , 'onStateChange': onPlayerStateChange
        }
    });
    app.ports.apiReady.send(null);
}

function onPlayerReady(event) {
    app.ports.playerReady.send(null);
}

function onPlayerStateChange(event) {
    app.ports.playerStateChange.send(event.data);
}
```

and in src/YTPlayer.elm

```
port apiReady : (() -> msg) -> Sub msg
port playerReady : (() -> msg) -> Sub msg
port playerStateChange : (Int -> msg) -> Sub msg

subscriptions : Sub Msg
subscriptions = Sub.batch
                [ apiReady (\_ -> ApiReady)
                , playerReady (\_ -> PlayerReady)
                , playerStateChange (PlayerStateChange << playerStateDecode)
                ]
```

## Installation of this app

[Note] assuming that elm and webpack is already installed in the global environment

For development build

```
git clone [URL of this repository]
npm install
npm start
```

Just for production build

`npm run build`

For production build with Japanese translation

`npm run build.ja`

In this case, index.html.ja is generated instead of index.html, which can be accessed on behavior
of index.html when 'Option MultiViews' is enabled in Apache httpd.conf



