FROM ubuntu:20.04 as build

RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      g++ \
      curl \
      ca-certificates \
      libc6-dev \
      make \
      libssl-dev \
      pkg-config \
      git \
      cmake \
      zlib1g-dev \
      clang \
      llvm \
      llvm-dev

COPY ./Cargo.lock ./Cargo.lock
COPY ./Cargo.toml ./Cargo.toml
COPY ./site ./site
COPY ./collector ./collector

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
    --default-toolchain stable --profile minimal -y

RUN bash -c 'source $HOME/.cargo/env && cargo build --release -p site'

FROM ubuntu:20.04 as binary

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates \
    git

COPY --from=build /target/release/site /usr/local/bin/rustc-perf-site
COPY --from=build /target/release/compact /usr/local/bin/rustc-perf-compact
COPY --from=build /target/release/ingest /usr/local/bin/rustc-perf-ingest
COPY --from=build site/static /site/static

EXPOSE 2346
CMD rustc-perf-site /opt/database/rocks /opt/database/rustc-timing
