# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM golang:1.18 as build
ARG  OTEL_VERSION=0.57.2
WORKDIR /app
COPY . .
RUN go install go.opentelemetry.io/collector/cmd/builder@v${OTEL_VERSION}
RUN builder --config=builder-config.yaml --name=otelcol-custom --output-path=.

FROM busybox:1.35.0-uclibc as busybox
FROM gcr.io/distroless/base-debian11
COPY --from=build /app/otelcol-custom /
COPY --from=busybox /bin/sh /bin/sh
COPY --from=busybox /bin/cat /bin/cat

# 4317 - default OTLP receiver
# 55678 - opencensus (tracing) receiver
# 55679 - zpages
EXPOSE 4317/tcp 55678/tcp 55679/tcp

CMD ["/otelcol-custom"]
