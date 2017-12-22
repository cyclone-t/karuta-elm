port module YTPlayer exposing (..)

--- Msg defs ---

type Msg
    = ApiReady
    | PlayerReady
    | PlayerStateChange PlayerState
    | CurrentTime Float

type PlayerState
    = PlayerStateUnstarted
    | PlayerStateEnded
    | PlayerStatePlaying
    | PlayerStatePaused
    | PlayerStateBuffering
    | PlayerStateCued
    | PlayerStateUnknown Int

--- Cmd msg ports ---

port playVideoWithTime : (Float, Float) -> Cmd msg
port playVideo : () -> Cmd msg
port pauseVideo : () -> Cmd msg

port getCurrentTime : () -> Cmd msg

--- Sub msg ports ---

port apiReady : (() -> msg) -> Sub msg
port playerReady : (() -> msg) -> Sub msg
port playerStateChange : (Int -> msg) -> Sub msg
port currentTime : (Float -> msg) -> Sub msg

subscriptions : Sub Msg
subscriptions = Sub.batch
                [ apiReady (\_ -> ApiReady)
                , playerReady (\_ -> PlayerReady)
                , playerStateChange (PlayerStateChange << playerStateDecode)
                , currentTime CurrentTime
                ]

--- decoder --

playerStateDecode : Int -> PlayerState
playerStateDecode n = case n of
                          -1 -> PlayerStateUnstarted
                          0 -> PlayerStateEnded
                          1 -> PlayerStatePlaying
                          2 -> PlayerStatePaused
                          3 -> PlayerStateBuffering
                          5 -> PlayerStateCued
                          others -> PlayerStateUnknown others
