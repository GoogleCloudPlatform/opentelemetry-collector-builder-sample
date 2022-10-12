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

include ../../../Makefile

define update-timestamp
	sed -i "s/%START_TIMESTAMP%/$$(date +%s)000000000/g" $(1)
	sed -i "s/%MIDDLE_TIMESTAMP%/$$(date +%s)000056783/g" $(1)
	sed -i "s/%END_TIMESTAMP%/$$(date +%s)000081234/g" $(1)
endef

.PHONY: udpate-timestamp-logs
update-timestamp-logs:
	$(call update-timestamp, ./otlp-data/testdata-logs.json)

.PHONY: udpate-timestamp-metrics
update-timestamp-metrics:
	$(call update-timestamp, ./otlp-data/testdata-metrics.json)

.PHONY: udpate-timestamp-traces
update-timestamp-traces:
	$(call update-timestamp, ./otlp-data/testdata-traces.json)

.PHONY: udpate-timestamp-all
update-timestamp-all: update-timestamp-logs update-timestamp-metrics update-timestamp-traces
