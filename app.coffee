express = require "express"
http    = require "http"
https   = require "https"
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
    url_accept_prefixes = [ "http://dl.dropbox.com/u/", "https://www.sugarsync.com/pf/" ]

    uri = req.url.substr(2)
    if url_accept_prefixes.every((x)->uri.indexOf(x) != 0)
        res.send "usage: " + req.headers.host + "/?url (dropbox or sugarsync)"
    else
        target = url.parse(uri)
        protocol = if target.protocol == "https:" then https else http
        protocol.get {host:target.hostname, path:target.pathname },
            (result)->
                if result.statusCode != 200
                    res.writeHead result.statusCode
                    res.end "error: " + result.statusCode
                    return

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

app.listen process.env.PORT || 3001
