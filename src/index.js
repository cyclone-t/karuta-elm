import './main.css';
import { Main } from './Main.elm';
import registerServiceWorker from './registerServiceWorker';

require('./bootstrap.min.css')

// --- needed for Youtube API .. from here
var tag = document.createElement('script');
tag.src = "https://www.youtube.com/iframe_api";
var firstScriptTag = document.getElementsByTagName('script')[0];
firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
 
var ytPlayer;
var playerId = 'youtube-player';
window.onYouTubeIframeAPIReady = function () {
    ytPlayer = new YT.Player(playerId, {
        events: {
            'onReady' : onPlayerReady
            , 'onStateChange': onPlayerStateChange
        }
    });
    app.ports.apiReady.send(null);
}
// --- to here

var app = Main.embed(document.getElementById('root'), playerId);

registerServiceWorker();

// PostMessage version (not needed)
// app.ports.videoControl.subscribe(function(args) {
//     var target_id = args[0];
//     var message_command = args[1];
//     var message_args = args[2];
// 
//     var player = document.getElementById(target_id).contentWindow;
//     var reqbody = JSON.stringify({event: "command", func: message_command, args: message_args});
// 
//     console.log("player=", player, "args=", reqbody);
// 
//     player.postMessage(reqbody, '*');
// });


// --- Port handlers for Youtube API ---

var timeoutId;

app.ports.playVideo.subscribe(function() {
    if (playerNotReady()) return;

    ytPlayer.playVideo();
});

app.ports.pauseVideo.subscribe(function() {
    if (playerNotReady()) return;

    ytPlayer.pauseVideo();
});

// var debugInterval;

app.ports.playVideoWithTime.subscribe(function(args) {
    if (playerNotReady()) return;

    var stime = args[0];
    var etime = args[1];

    // debug
    // if (debugInterval) clearInterval(debugInterval);
    // debugInterval = setInterval(function() { console.log('state', ytPlayer.getPlayerState()); }, 200);

    // seek and play
    ytPlayer.seekTo(stime, true);
    ytPlayer.playVideo();

    // stop at specified timing
    stopVideoWithTimeInternal(etime);
});

function onPlayerReady(event) {
    // console.log('player ready callback');
    app.ports.playerReady.send(null);
}

function onPlayerStateChange(event) {
    // console.log('state change callback', event.data);
    app.ports.playerStateChange.send(event.data);
}

// --- utitility ---

function stopVideoWithTimeInternal(etime) {
    if (playerNotReady()) return;

    var status = ytPlayer.getPlayerState();
    console.log("status = ", status);
    // wait until playback start
    if (status !== 1) {
        timeoutId = setTimeout(stopVideoWithTimeInternal, 1000, etime);
        return;
    }

    var ctime = ytPlayer.getCurrentTime();
    var wtime = (etime - ctime) * 1000.0;
    console.log("etime = ", etime, "ctime = ", ctime, ", wtime = ", wtime);
    // the case 'wtime < -500' indicates 'seekTo not finished'
    if (wtime <= 0 && wtime > -500) {
        // pause and exit
        ytPlayer.pauseVideo();
    } else {
        // keep on waiting
        timeoutId = setTimeout(stopVideoWithTimeInternal, wtime, etime);
    }
}

function playerNotReady() {
    if (timeoutId) {
        clearTimeout(timeoutId);
        timeoutId = undefined;
    }

    if (!ytPlayer) {
        console.log('YTPlayer is not ready');
        return true;
    }
    return false;
}

