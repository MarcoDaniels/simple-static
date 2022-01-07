port module Main exposing (main)


port inputPort : (String -> msg) -> Sub msg


port outputPort : Response -> Cmd msg


type alias Model =
    { input : String }


type Msg
    = Incoming String


type alias Response =
    { status : String
    , statusDescription : String
    , body : String
    }


buildResponse : String -> Response
buildResponse input =
    { status = "200"
    , statusDescription = "OK"
    , body = input ++ " from ELM"
    }


main : Program () Model Msg
main =
    Platform.worker
        { init = \_ -> ( { input = "" }, Cmd.none )
        , update =
            \msg model ->
                case msg of
                    Incoming arg ->
                        ( { model | input = arg }, outputPort (buildResponse arg) )
        , subscriptions = \_ -> inputPort Incoming
        }
