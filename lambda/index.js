const {Elm} = require('./Main')
const app = Elm.Main.init()

const input = process.argv[2]

app.ports.input.send(input)

app.ports.output.subscribe((content) => {
    console.log(content)
})
