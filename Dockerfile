# Stage 1: Build executable
FROM golang:1.9.2 as buildImage
 
WORKDIR /go/src/github.com/Soluto/golang-docker-healthcheck
COPY main.go .
COPY healthcheck ./healthcheck

RUN CGO_ENABLED=0 go build -a -installsuffix cgo -o server
RUN CGO_ENABLED=0 go build -a -installsuffix cgo -o health-check "github.com/Soluto/golang-docker-healthcheck/healthcheck"

# Stage 2: Create release image
FROM scratch as releaseImage

COPY --from=buildImage /go/src/github.com/Soluto/golang-docker-healthcheck/server ./server
COPY --from=buildImage /go/src/github.com/Soluto/golang-docker-healthcheck/health-check ./healthcheck

HEALTHCHECK --interval=1s --timeout=1s --start-period=2s --retries=3 CMD [ "/healthcheck" ]

ENV PORT=8080
EXPOSE $PORT

ENTRYPOINT [ "/server" ]