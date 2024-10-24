FROM elixir:1.17-otp-27-alpine AS builder

ENV MIX_ENV=prod

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
