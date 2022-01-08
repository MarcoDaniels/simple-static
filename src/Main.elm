port module Main exposing (main)

import Event exposing (CFConfigResponse, CloudFront, Event, Request)
import Json.Decode as Decode exposing (Error)


port inputPort : (Decode.Value -> msg) -> Sub msg


port outputPort : Response -> Cmd msg


type alias Model =
    { event : Maybe Event }


type Msg
    = Incoming (Result Error Event)


type alias Response =
    { status : String, statusDescription : String, body : String }


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
                                    { status = "200"
                                    , statusDescription = "OK"
                                    , body =
                                        event.records
                                            |> List.map (\{ cf } -> cf.request.clientIp)
                                            |> String.concat
                                    }
                                )

                            Err _ ->
                                ( model, Cmd.none )
        , subscriptions = \_ -> inputPort (decodeEvent >> Incoming)
        }


decodeEvent : Decode.Value -> Result Error Event
decodeEvent =
    Decode.decodeValue
        (Decode.map Event
            (Decode.field "Records"
                (Decode.list
                    (Decode.map CloudFront
                        (Decode.field "cf"
                            (Decode.map CFConfigResponse
                                (Decode.field "request"
                                    (Decode.map Request
                                        (Decode.field "clientIp" Decode.string)
                                    )
                                )
                            )
                        )
                    )
                )
            )
        )
