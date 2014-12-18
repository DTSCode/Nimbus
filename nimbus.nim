import parseopt2
import strutils
import sockets
import osproc

proc version(): string =
    result = "v1.0.0"

proc about(): string =
    result = "Nimbus - Nim Eval IRC Bot (" & version() & ")"

proc help(topic: string): string =
    if topic == "":
        result = about() & "\n"
        result &= " -s, --server=<server>     :: Assigns a server for Nimbus to connect to. Default is irc.freenode.net\n" &
                  " -p, --port=<port>         :: Assigns a port for Nimbus to connect on. Default is 6667\n" &
                  " -u, --username=<user>     :: Assigns a username to Nimbus. Default is NimbusBot\n" &
                  " -n, --nick=<nick>         :: Assigns a nick for to Nimbus. Default is Nimbus\n" &
                  " -c, --channels=<channels> :: Assigns a list of channels for Nimbus to connect to (seperated by comma and with no #. Default is #nim and #nim-offtopic\n" &
                  " -a, --auth=<password>     :: Assigns a password to Nimbus for authenticating with the server. If --auth is not passed, no authentication is done\n" &
                  " -l, --log=<log>           :: Logs the output to <log>"

    else:
        result = "fooey"

proc chansplit(raw: string): seq[string] =
    result = @[]

    for channel in split(raw, ","):
        add(result, "#" & channel)

proc getNick(raw: string): string =
    result = raw[1 .. (find(raw, '!') - 1)]

var server: string = "irc.freenode.net"
var port: Port = 6667.Port
var username: string = "NimbusBot"
var nick: string = "Nimbus"
var pass: string = ""
var channels: seq[string] = @["#nim", "#nim-offtopic"]
var log: File
var islogging: bool = false

for kind, key, val in getopt():
    case kind:
        of cmdArgument:
            discard

        of cmdLongOption, cmdShortOption:
            case key:
                of "v", "version":
                    echo(version())
                    quit()

                of "a", "about":
                    echo(about())
                    quit()

                of "h", "help":
                    echo(help(val))
                    quit()

                of "s", "server":
                    server = val

                of "p", "port":
                    port = parseInt(val).Port

                of "u", "username":
                    username = val

                of "n", "nick":
                    nick = val

                of "c", "channels":
                    channels = chansplit(val)
                    echo($channels)

                of "l", "log":
                    log = open(val, fmWrite)
                    islogging = true

                else:
                    writeln(stderr, "invalid parameter: " & key)

        of cmdEnd:
            assert(false)

var sock: Socket = socket()
var buffer: string = ""

connect(sock, server, port)

send(sock, "NICK " & nick & "\r\n")
send(sock, "USER " & nick & " " & nick & " " & nick & " :Nimbus IRC\r\n")

if pass != "":
    send(sock, "PRIVMSG NickServ :identify " & pass & "\r\n")

send(sock, "MODE " & nick & " +i\r\n")

while true:
    readLine(sock, buffer)

    if islogging:
        writeln(log, buffer)

    echo(buffer)

    if (endsWith(buffer, "is now your hidden host (set by services.)")) or (pass == "" and endsWith(buffer, "MODE " & nick & " :+i")):
        break

for channel in channels:
    send(sock, "JOIN " & channel & "\r\n")

while true:
    readLine(sock, buffer)

    if buffer == "":
        echo("connection is closed")
        break

    if islogging:
        writeln(log, buffer)

    var ircmsg = split(buffer, " ")
    echo($ircmsg)

    if ircmsg[0] == "PING":
        send(sock, "PONG " & ircmsg[1] & "\r\n")

    elif ircmsg[1] == "PRIVMSG":
        var nick: string = getNick(ircmsg[0])

        if ircmsg[3] == ":,eval":
            let filename = "eval.nim"
            var outHandle = open(filename, fmWrite)
            var result: string

            outHandle.writeln(join(ircmsg[4 .. ircmsg.high], " "))
            close(outHandle)

            var resultInitial = execCmdEx("nim compile --stackTrace:off --lineTrace:off --threads:off --checks:on --deadCodeElim:off --opt:speed --warnings:off --hints:off --verbosity:0 " & filename)

            if resultInitial.output == "":
                var resultSecond = execCmdEx("./" & filename[0 .. (filename.len - ".nim".len - 1)])

                if resultSecond.output == "":
                    result = "<no output>"

                else:
                    result = resultSecond.output

            else:
                result = resultInitial.output

            send(sock, "PRIVMSG " & ircmsg[2] & " :" & nick & ": " & result & "\r\n")
close(log)
close(sock)
