port module Main exposing (main)

import CloudWorker.AWS exposing (Event, Output(..), decodeEvent, encodeOutput)
import Dict
import Json.Decode as Decode exposing (Decoder, Error)
import Json.Encode as Encode


port inputPort : (Decode.Value -> msg) -> Sub msg


port outputPort : Encode.Value -> Cmd msg


type alias Model =
    { event : Maybe Event }


type Msg
    = Incoming (Result Error Event)


main : Program () Model Msg
main =
    Platform.worker
        { init = \_ -> ( { event = Nothing }, Cmd.none )
        , update =
            \msg model ->
                case msg of
                    Incoming result ->
                        case result of
                            Ok event ->
                                ( { model | event = Just event }
                                , outputPort
                                    (encodeOutput
                                        (Res
                                            { status = "200"
                                            , statusDescription = "OK"
                                            , body =
                                                event.records
                                                    |> List.map
                                                        (\{ cf } ->
                                                            (cf.request.headers
                                                                |> Dict.keys
                                                                |> List.map (\key -> key)
                                                            )
                                                                |> String.join ", "
                                                        )
                                                    |> String.concat
                                            , headers =
                                                event.records
                                                    |> List.foldr (\{ cf } _ -> cf.request.headers) Dict.empty
                                            }
                                        )
                                    )
                                )

                            Err _ ->
                                ( model, Cmd.none )
        , subscriptions = \_ -> inputPort (Decode.decodeValue decodeEvent >> Incoming)
        }
