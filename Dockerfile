# Build stage 0
FROM erlang:24 AS build

# Set working directory
RUN mkdir /buildroot
WORKDIR /buildroot

# Copy our Erlang test application
COPY . flightFilterApp

# And build the release
WORKDIR flightFilterApp
RUN rebar3 as prod release

# Build stage 1
FROM ubuntu:latest

# Install some libs
RUN apt-get update && apt-get install libssl-dev -y

# Install the released application
COPY --from=0 /buildroot/flightFilterApp/_build/prod/rel/flightFilterApp /flightFilterApp

# Expose relevant ports
EXPOSE 8080
EXPOSE 8443

ADD https://github.com/ufoscout/docker-compose-wait/releases/download/2.9.0/wait /wait
RUN chmod +x /wait

COPY --chown=777:777 --from=build /buildroot/flightFilterApp/src/augmentor_config.json /flightFilterApp/
CMD /wait && /flightFilterApp/bin/flightFilterApp foreground