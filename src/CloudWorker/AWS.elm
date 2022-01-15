module CloudWorker.AWS exposing (Event, Output(..), decodeEvent, encodeOutput)

{-| Types based on:
<https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-event-structure.html#request-event-fields>
-}

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder, Error)
import Json.Decode.Pipeline as Decode
import Json.Encode as Encode


type alias Config =
    { distributionDomainName : String
    , distributionId : String
    , eventType : String
    , requestId : String
    }


type alias Header =
    { key : String, value : String }


type alias Request =
    { clientIp : String
    , headers : Dict.Dict String (List Header)
    , method : String
    , querystring : Maybe String
    , uri : String
    }


type alias Response =
    { status : String
    , statusDescription : String
    , headers : Dict.Dict String (List Header)
    , body : String
    }


type alias CloudFront =
    { config : Config
    , request : Request
    }


type alias Record =
    { cf : CloudFront }


type alias Event =
    { records : List Record }


decodeHeader : Decoder Header
decodeHeader =
    Decode.succeed Header
        |> Decode.required "key" Decode.string
        |> Decode.required "value" Decode.string


decodeRequest : Decoder Request
decodeRequest =
    Decode.succeed Request
        |> Decode.required "clientIp" Decode.string
        |> Decode.required "headers" (Decode.dict (Decode.list decodeHeader))
        |> Decode.required "method" Decode.string
        |> Decode.required "querystring" (Decode.maybe Decode.string)
        |> Decode.required "uri" Decode.string


decodeConfig : Decoder Config
decodeConfig =
    Decode.succeed Config
        |> Decode.required "distributionDomainName" Decode.string
        |> Decode.required "distributionId" Decode.string
        |> Decode.required "eventType" Decode.string
        |> Decode.required "requestId" Decode.string


decodeCloudFront : Decoder Record
decodeCloudFront =
    Decode.succeed Record
        |> Decode.required "cf"
            (Decode.succeed CloudFront
                |> Decode.required "config" decodeConfig
                |> Decode.required "request" decodeRequest
            )


decodeEvent : Decoder Event
decodeEvent =
    Decode.succeed Event
        |> Decode.required "Records"
            (Decode.list decodeCloudFront)



-- TODO:  not the best name


type Output
    = Res Response
    | Req Request


encodeHeaders : Dict.Dict String (List Header) -> Encode.Value
encodeHeaders headers =
    headers
        |> Encode.dict identity
            (Encode.list
                (\header ->
                    Encode.object
                        [ ( "key", Encode.string header.key )
                        , ( "value", Encode.string header.value )
                        ]
                )
            )


encodeQuerystring : Maybe String -> Encode.Value
encodeQuerystring maybeQuerystring =
    maybeQuerystring
        |> Maybe.map Encode.string
        |> Maybe.withDefault Encode.null


encodeOutput : Output -> Encode.Value
encodeOutput out =
    case out of
        Res res ->
            Encode.object
                [ ( "status", Encode.string res.status )
                , ( "statusDescription", Encode.string res.statusDescription )
                , ( "headers", res.headers |> encodeHeaders )
                , ( "body", Encode.string res.body )
                ]

        Req req ->
            Encode.object
                [ ( "clientIp", Encode.string req.clientIp )
                , ( "headers", req.headers |> encodeHeaders )
                , ( "method", Encode.string req.method )
                , ( "querystring", req.querystring |> encodeQuerystring )
                , ( "uri", Encode.string req.uri )
                ]
