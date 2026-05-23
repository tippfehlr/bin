FROM --platform=$BUILDPLATFORM rust:1-alpine AS builder

# xx provides cross-compilation helpers that auto-detect the target
# architecture from TARGETPLATFORM and configure the sysroot.
COPY --from=tonistiigi/xx / /

RUN apk add --no-cache musl-dev clang lld llvm && \
	xx-apk add --no-cache musl-dev

RUN rustup target add $(xx-cargo --print-target-triple)

COPY . /sources
WORKDIR /sources

# Build the project. xx-cargo automatically configures cross-compilation and linkers.
RUN xx-cargo build --release && \
	cp "target/$(xx-cargo --print-target-triple)/release/bin" /pastebin && \
	chown nobody:nogroup /pastebin

# Verify the binary is for the correct architecture.
RUN xx-verify /pastebin

FROM scratch
COPY --from=builder /pastebin /pastebin
COPY --from=builder /etc/passwd /etc/passwd

USER nobody
EXPOSE 8000
ENTRYPOINT ["/pastebin", "0.0.0.0:8000"]
