FROM ruby:2.3-alpine

ENV PASSENGER_VERSION="5.1.7" \
    PATH="/opt/passenger/bin:$PATH" \
    PASSENGER_MIN_INSTANCES="3" \
    PASSENGER_MAX_POOL_SIZE="3" \
    BUNDLE_JOBS=4

RUN PACKAGES="ca-certificates procps curl pcre libstdc++ libexecinfo" && \
    BUILD_PACKAGES="build-base linux-headers curl-dev pcre-dev libexecinfo-dev" && \
    echo 'http://alpine.gliderlabs.com/alpine/edge/main' >> /etc/apk/repositories && \
    echo 'http://alpine.gliderlabs.com/alpine/edge/testing' >> /etc/apk/repositories && \
    apk add --update $PACKAGES $BUILD_PACKAGES && \
# download and extract
    mkdir -p /opt && \
    curl -L https://s3.amazonaws.com/phusion-passenger/releases/passenger-$PASSENGER_VERSION.tar.gz | tar -xzf - -C /opt && \
    mv /opt/passenger-$PASSENGER_VERSION /opt/passenger && \
    export EXTRA_PRE_CFLAGS='-O' EXTRA_PRE_CXXFLAGS='-O' EXTRA_LDFLAGS='-lexecinfo' && \
# compile agent
    passenger-config compile-agent --auto --optimize && \
    passenger-config install-standalone-runtime --auto --url-root=fake --connect-timeout=1 && \
    passenger-config build-native-support && \
# app directory
    mkdir -p /usr/src/app && \
# Cleanup passenger src directory
    rm -rf /tmp/* && \
    mv /opt/passenger/src/ruby_supportlib /tmp && \
    mv /opt/passenger/src/nodejs_supportlib /tmp && \
    mv /opt/passenger/src/helper-scripts /tmp && \
    rm -rf /opt/passenger/src/* && \
    mv /tmp/* /opt/passenger/src/ && \
# Cleanup
    passenger-config validate-install --auto && \
    apk del $BUILD_PACKAGES && \
    rm -rf /var/cache/apk/* \
        /tmp/* \
        /opt/passenger/doc

WORKDIR /usr/src/app
EXPOSE 3000

ENTRYPOINT ["passenger", "start", "--no-install-runtime", "--no-compile-runtime"]
