ARG BASE_IMAGE=alpine:3.9
FROM ${BASE_IMAGE}
RUN apk add --force-refresh ca-certificates

# Add non-root user
RUN addgroup -S app && adduser -S -g app app \
  && mkdir -p /home/app || : \
  && chown -R app /home/app

WORKDIR /home/app
ARG INLETS_BINARY="./bin/inlets"
COPY ${INLETS_BINARY} /home/app/inlets

USER app
EXPOSE 80

ENTRYPOINT ["./inlets"]
CMD ["-help"]
