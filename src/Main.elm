module Main exposing (main)

import AWS exposing (Event, EventResult(..))
import CloudWorker exposing (originRequest, toCloudWorker, withHeader)
import Dict


main : Program () CloudWorker.Model CloudWorker.Msg
main =
    originRequest
        { request =
            withHeader
                (Dict.insert "my-head"
                    [ { key = "what", value = "hey" } ]
                    Dict.empty
                )
        }
        |> toCloudWorker
