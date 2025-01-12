FROM opensuse/tumbleweed

WORKDIR /app

RUN zypper -n install tini \
 && zypper -n clean

COPY wait_until_ready.sh /app

RUN chown -R 1000:1000 /app \
 && chmod a+x /app/wait_until_ready.sh

USER 1000
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["sh", "/app/wait_until_ready.sh"]

LABEL maintainer="Mark Himsley <mark@himsley.org>"
