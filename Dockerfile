####################################################################################################
## Builder
####################################################################################################
FROM rust:latest AS builder

RUN rustup target add x86_64-unknown-linux-musl
RUN apt update && apt install -y musl-tools musl-dev
RUN update-ca-certificates

# Create appuser
ENV USER=relay_v2
ENV UID=10001

RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    "${USER}"


WORKDIR /relay_v2

COPY ./ .

RUN cargo build --example relay_v2 -p libp2p-relay --target x86_64-unknown-linux-musl --release

####################################################################################################
## Final image
####################################################################################################
FROM alpine:latest

# Import from builder.
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

WORKDIR /relay_v2

# Copy our build
COPY --from=builder /relay_v2/target/x86_64-unknown-linux-musl/release/examples/relay_v2 ./

# Use an unprivileged user.
USER relay_v2:relay_v2

CMD ["/relay_v2/relay_v2"]