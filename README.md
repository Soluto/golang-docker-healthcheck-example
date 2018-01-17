# Golang Docker HEALTHCHECK
### Simple HEALTHCHECK solution for Go Docker container

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/soluto/tweek/blob/master/LICENSE.md)

## How it began

At [Soluto](https://blog.solutotlv.com/) we are working on an open-source project named [Tweek](https://github.com/Soluto/tweek).
One of its components is a proxy server that we decided to implement in Go.

In order to dockerize our environment we wrote Dockerfile for the server.
We built the container from scratch since it's popular in Go.

```docker
# Stage 1: Build executable
FROM golang:1.9.2 as buildImage
 
WORKDIR /go/src/github.com/Soluto/golang-docker-healthcheck
COPY main.go .

RUN CGO_ENABLED=0 go build -a -installsuffix cgo -o server

# Stage 2: Create release image
FROM scratch as releaseImage

COPY --from=buildImage /go/src/github.com/Soluto/golang-docker-healthcheck/server ./server

ENV PORT=8080
EXPOSE $PORT

ENTRYPOINT [ "/server" ]
```

## The Problem
We usually add a `HEALTHCHECK` instruction to our Dockerfiles and then check their status with the `docker inspect` command.
Usually the health check performs an http request to server endpoint, and if it succeeds the server is considered in healthy condition.
In Linux-based containers we do it with the `curl` or `wget` command.
The problem is that in containers built from scratch there are no such commands.

## Solution
We decided to add a new package that contains several lines...

```go
_, err := http.Get(fmt.Sprintf("http://127.0.0.1:%s/health", os.Getenv("PORT")))
if err != nil {
	os.Exit(1)
}
```

... and then build the package as another executable, and add the `HEALTHCHECK` instruction to the `Dockerfile`

```docker
...
RUN CGO_ENABLED=0 go build -a -installsuffix cgo -o server
RUN CGO_ENABLED=0 go build -a -installsuffix cgo -o health-check "github.com/Soluto/golang-docker-healthcheck/healthcheck"

# Stage 2: Create release image
FROM scratch as releaseImage

COPY --from=buildImage /go/src/github.com/Soluto/golang-docker-healthcheck/server ./server
COPY --from=buildImage /go/src/github.com/Soluto/golang-docker-healthcheck/health-check ./healthcheck

HEALTHCHECK --interval=1s --timeout=1s --start-period=2s --retries=3 CMD [ "/healthcheck" ]
...
```

So we now have two executables in the docker container: the server and the health-check utility.

## Conclusion
In this repository we demonstrated a health-check for a server implemented in Go, for a docker container built from scratch. 

If you want to see a real-world application, please visit the [Tweek project](https://github.com/Soluto/tweek/tree/secure-gateway/services/secure-gateway).

In general, we think this approach can be used for checks other than http requests.