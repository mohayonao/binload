express = require "express"
http    = require "http"
url     = require "url"

app = module.exports = express.createServer()

app.configure ->
    app.use express.bodyParser()
    app.use express.methodOverride()
    app.use app.router


app.configure "development", ->
    app.use express.errorHandler(dumpException:true, showStack:true)

app.configure "production", ->
    app.use express.errorHandler()

app.get "/", (req, res)->

    uri = req.url.substr(2)
    if not uri
        res.send "usage: " + req.headers.host + "/?url";
        return

    target = url.parse(uri)
    console.log target
    http.get {host:target.hostname, path:target.pathname },
        (result)->
            if result.statusCode == 200
                body = []
                result.setEncoding "binary"
                result.on "data", (chunk)->
                    body.push chunk
                result.on "end", ()->
                    bin = new Buffer(body.join(""), "binary")
                    res.writeHead(200, {
                        "Content-Length": bin.length,
                        "Content-Type": result.headers["content-type"],
                        "Access-Control-Allow-Origin": "*"
                    });
                    res.end bin
            else
                console.log res
                res.writeHead result.statusCode
                res.end "error: " + result.statusCode

app.listen process.env.PORT || 3001
