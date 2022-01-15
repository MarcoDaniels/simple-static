const {Elm} = require('./Main')
const app = Elm.Main.init()

exports.handler = (event, context, callback) => {
    app.ports.incomingEvent.send(event)
    app.ports.outgoingResult.subscribe((response) =>
        callback(null, response)
    )
}