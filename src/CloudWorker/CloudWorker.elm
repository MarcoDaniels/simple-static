port module CloudWorker.CloudWorker exposing (..)

import CloudWorker.AWS exposing (Event, EventResult, decodeEvent, encodeEventResult)
import Json.Decode as Decode exposing (Error)
import Json.Encode as Encode


port incomingEvent : (Decode.Value -> msg) -> Sub msg


port outgoingResult : Encode.Value -> Cmd msg


type alias Model =
    { event : Maybe Event }


type Msg
    = Incoming (Result Error Event)


cloudWorker : (Event -> EventResult) -> Program () Model Msg
cloudWorker eventResult =
    Platform.worker
        { init = \_ -> ( { event = Nothing }, Cmd.none )
        , update =
            \msg model ->
                case msg of
                    Incoming result ->
                        case result of
                            Ok event ->
                                ( { event = Just event }
                                , eventResult event
                                    |> encodeEventResult
                                    |> outgoingResult
                                )

                            Err _ ->
                                ( model, Cmd.none )
        , subscriptions =
            \_ ->
                Decode.decodeValue decodeEvent
                    >> Incoming
                    |> incomingEvent
        }
