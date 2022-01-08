const {Elm} = require('./Main')
const app = Elm.Main.init()

exports.handler = (event, context, callback) => {
    app.ports.inputPort.send(event)
    app.ports.outputPort.subscribe((response) =>
        callback(null, response)
    )
}