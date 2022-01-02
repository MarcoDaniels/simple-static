module Main exposing (..)

main : Program () () ()
main =
    Platform.worker
        { init = \flags -> ( flags, Cmd.none )
        , update = \msg model -> ( model, Cmd.none )
        , subscriptions = \_ -> Sub.none
        }
