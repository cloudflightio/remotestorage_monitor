FROM alpine

MAINTAINER stefan.himpich@cloudflight.io

RUN apk update \
    && apk add lighttpd \
    && apk add bash \
    && apk add rclone \
    && apk add curl \
    && rm -rf /var/cache/apk/*

# supercronic install
ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.1.11/supercronic-linux-amd64 \
    SUPERCRONIC=supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=a2e2d47078a8dafc5949491e5ea7267cc721d67c

RUN curl -fsSLO "$SUPERCRONIC_URL" \
 && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
 && chmod +x "$SUPERCRONIC" \
 && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
 && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic
# end of supercronic install

WORKDIR /app

COPY ./index.html /app/htdocs/index.html
COPY ./lighttpd.conf /app/
COPY scripts/* /app/
RUN chmod -R g+w /app /run

CMD ["/app/init.sh"]

