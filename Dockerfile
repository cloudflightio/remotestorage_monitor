FROM alpine

MAINTAINER stefan.himpich@cloudflight.io

RUN apk update \
    && apk add lighttpd \
    && apk add bash \
    && apk add rclone \
    && rm -rf /var/cache/apk/*

WORKDIR /app

COPY ./index.html /app/htdocs/index.html
COPY ./lighttpd.conf /app
COPY scripts/init.sh /app
COPY scripts/run_test.sh /app
RUN chmod -R g+w /app /run


CMD ["/app/init.sh"]

