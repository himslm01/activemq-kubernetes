FROM opensuse/tumbleweed AS stage

WORKDIR /app

RUN zypper -n install tar gzip \
 && zypper -n clean

ARG activemq_version=5.18.6
RUN curl -L \
    -o amq.tar.gz \
    "https://www.apache.org/dyn/closer.cgi?filename=/activemq/${activemq_version}/apache-activemq-${activemq_version}-bin.tar.gz&action=download" \
 && tar -xvf amq.tar.gz \
 && mv "apache-activemq-${activemq_version}" activemq \
 && rm amq.tar.gz

ARG postgresqljdbc_version=42.5.1
RUN curl -L \
    -o "activemq/lib/postgresql-${postgresqljdbc_version}.jar" \
    "https://jdbc.postgresql.org/download/postgresql-${postgresqljdbc_version}.jar"

RUN chown 1000:1000 /app/activemq \
 && chown -R 1000:1000 /app/activemq/data

FROM adoptopenjdk/openjdk11:jre-11.0.18_10-tumbleweed

WORKDIR /app

RUN zypper -n install tini jq \
 && zypper -n clean

COPY --from=stage /app /app

USER 1000
VOLUME [ "/app/activemq/data" ]
EXPOSE 8161 61616 5672 61613 1833
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/app/activemq/bin/activemq","console"]

LABEL maintainer="Mark Himsley <mark@himsley.org>"
