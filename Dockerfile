# 1.17-otp-27-alpine
FROM elixir@sha256:6b01b34153703e9a4877e33f54d891e30b26fb2832479dfa958a7aec0511b0af AS builder

ENV MIX_ENV=prod

# RUN apk add python3 git build-base make cmake gcc libc-dev curl cargo &&\
#   ln -sf $(which python3) /usr/bin/python

WORKDIR /opt/app

COPY . .

RUN mix local.hex --force &&\
  mix local.rebar --force &&\
  mix deps.get &&\
  mix deps.compile &&\
  mix release

FROM alpine:3.20
LABEL maintainer="legend@shadowlegend.me"

ENV LANG=en_US.UTF-8\
  HOME=/opt/app\
  MIX_ENV=prod\
  REPLACE_OS_VARS=true\
  PLUG_TMPDIR=/opt/app/plug_tmp\
  LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64\
  SHELL=/bin/bash
WORKDIR $HOME

RUN apk --no-cache add openssl bash libstdc++ &&\
  addgroup genx &&\
  adduser -D -G genx xuser &&\
  mkdir -p $HOME/uploads $HOME/logs

COPY --from=builder $HOME/_build/prod/rel/aasa_assetlinks_server/. $HOME/

RUN chown -R xuser:genx $HOME

USER xuser

VOLUME $HOME/uploads

ENTRYPOINT ["bin/aasa_assetlinks_server"]
CMD ["start"]
