module Main exposing (..)

import Bootstrap.Button as Button
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Exts.Maybe as Maybe
import Html exposing (Html, text, div, h1, iframe, img)
import Html.Attributes exposing (src, height, id, width, class)
import List.Extra as List
import Random
import Random.List as Random

import Translation.Common as T exposing (..)
import YTPlayer as YP

---- MODEL ----


type PlaybackMode
    = PlaybackModeSequencial
    | PlaybackModeRandom

type alias Model =
    { playerId : String
    , playerReady : Bool
    , playbackMode : PlaybackMode
    , indexList : List Int
    , currIndex : Int
    , start : Bool
    }


type alias SiteConfig =
    { videoId : String
    , timingList : List Float
    , marginTime : Float
    }

siteConfig : SiteConfig
siteConfig = { videoId = "ZKgqHQfgsT8"
             , timingList = [ 8
                            , 35.5, 53,  70.5, 88, 105.5, 123, 140.5, 158, 175.5, 193
                            , 211, 228.5, 245.7, 263.2, 280.7, 298.3, 315.8, 333.4, 351, 368.5
                            , 386, 403.7, 421.2, 438.7, 456.2, 473.8, 491.3, 508.8, 526.3, 544
                            , 561.4, 578.9, 596.4, 614.1, 631.6, 649.2, 666.7, 684.2, 701.8, 719.4
                            , 736.9, 754.4, 772, 789.5, 807, 824.5, 842.1, 859.6, 877.2, 894.8
                            , 912.4, 929.8, 947.4, 964.9, 982.6, 1000.1, 1017.6, 1035.1, 1052.6, 1070.2
                            , 1087.8, 1105.2, 1122.9, 1140.3, 1158, 1175.4, 1193, 1210.5, 1228, 1245.6
                            , 1263.2, 1280.7, 1298.2, 1315.7, 1333.2, 1350.8, 1368.3, 1385.8, 1403.4, 1421
                            , 1438.5, 1456, 1473.5, 1491.1,   1508.6, 1526.2, 1543.7, 1561.3, 1578.8, 1596.4
                            , 1613.9, 1631.5, 1649, 1666.5,    1684.1, 1701.6, 1719.2, 1736.7, 1754.2, 1771.7
                            , 1788.5]
             , marginTime = 0.5
             }

init : String -> ( Model, Cmd Msg )
init flag =
    ( { playerId = flag, playerReady = False, playbackMode = PlaybackModeSequencial, indexList = mkSequencial siteConfig.timingList, currIndex = 0, start = True}, Cmd.none )

-- Joka(intro) + 100 songs
mkSequencial : List a -> List Int
mkSequencial lst = List.range 0 <| List.length lst - 2

-- shuffle the index except Joka
mkRandom : List a -> Cmd Msg
mkRandom = Maybe.maybe Cmd.none (Random.generate MsgGenerateShuffle << Random.shuffle << mkSequencial) << List.tail

---- UPDATE ----


type Msg
    = MsgPlay
    | MsgPrev
    | MsgNext
    | MsgRestart
    | MsgShuffle
    | MsgGenerateShuffle (List Int)
    | MsgYTPlayer YP.Msg

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "---message---" msg of
        MsgPlay -> playWithIndexOffset model 0
        MsgPrev -> playWithIndexOffset model -1
        MsgNext -> playWithIndexOffset model 1
        MsgRestart -> ({ model | currIndex = 0, start = True}, Cmd.none)
        MsgShuffle -> (model, mkRandom siteConfig.timingList)
        MsgGenerateShuffle index_list -> ({ model | indexList = 0 :: index_list, currIndex = 0, start = True}, Cmd.none)
        MsgYTPlayer m -> case m of
                             YP.PlayerReady -> ({ model | playerReady = True}, Cmd.none)
                             YP.ApiReady -> (model, Cmd.none)
                             YP.PlayerStateChange s -> (model, Cmd.none)
                             YP.CurrentTime t -> (model, Cmd.none)

playWithIndexOffset : Model -> Int -> ( Model, Cmd Msg )
playWithIndexOffset model index_offset = 
    let
        new_index = model.currIndex + index_offset
        t_index = List.getAt new_index model.indexList
        stime = Maybe.maybe Nothing (\i -> List.getAt i siteConfig.timingList) t_index
        etime = Maybe.maybe Nothing (\i -> List.getAt (i + 1) siteConfig.timingList) t_index
    in
        case (stime, etime) of
            (Just st, Just et) -> ( { model | currIndex = new_index, start = False}, YP.playVideoWithTime (st, et - siteConfig.marginTime) )
            _ -> ( model, Cmd.none )

---- VIEW ----

view : Model -> Html Msg
view model =
    Grid.container []
        [ Grid.row [rowMargin] <|
              [ Grid.col [Col.lg12]
                   [ iframe [id model.playerId
                            , src <| "https://www.youtube.com/embed/" ++ siteConfig.videoId ++ "?enablejsapi=1"
                            , width 560
                            , height 315
                            ] []
                   ]
              , Grid.col [Col.lg12] [div [id "video2"] []]

              ]
        , Grid.row [rowMargin]
              [ Grid.col [Col.lg12]
                    [ Button.button [buttonMargin, Button.secondary, Button.onClick MsgRestart] [text T.restart]
                    ,  Button.button [buttonMargin, Button.secondary, Button.onClick MsgShuffle] [text T.shuffle]
                    ]
              ]
        , Grid.row [rowMargin]
              [ Grid.col [Col.lg12] <|
                    let
                        next_button = Button.button [Button.primary, buttonMargin, Button.onClick MsgNext] [text T.next]
                        prev_button = Button.button [Button.secondary ,buttonMargin, Button.onClick MsgPrev] [text T.previous]
                        play_button style txt = Button.button [style, buttonMargin, Button.onClick MsgPlay] [text txt]
                        start_button = play_button Button.primary T.start
                        replay_button = play_button Button.secondary T.replay

                        buttons = case position model of
                                      PositionInit -> [ start_button ]
                                      PositionStart -> [ replay_button, next_button ]
                                      PositionMiddle -> [ prev_button, replay_button, next_button ]
                                      PositionEnd -> [ prev_button, replay_button ]
                    in
                        [viewIndex model] ++ if model.playerReady then buttons else []
              ]
        ]

viewIndex : Model -> Html Msg
viewIndex model =
    let
        size = List.length model.indexList - 1
        curr = model.currIndex
    in
        text <| toString curr ++ " / " ++ toString size

buttonMargin : Button.Option Msg
buttonMargin = Button.attrs [ class "mx-1"]

rowMargin : Row.Option Msg
rowMargin = Row.attrs [ class "mt-4"]

type Position
    = PositionInit
    | PositionStart
    | PositionMiddle
    | PositionEnd

position : Model -> Position
position model = if model.start
                 then PositionInit
                 else if model.currIndex == 0
                      then PositionStart
                      else if model.currIndex == List.length model.indexList - 1
                           then PositionEnd
                           else PositionMiddle

---- PROGRAM ----


main : Program String Model Msg
main =
    Html.programWithFlags
        { view = view
        , init = init
        , update = update
        , subscriptions = \_ -> Sub.map MsgYTPlayer YP.subscriptions
        }
