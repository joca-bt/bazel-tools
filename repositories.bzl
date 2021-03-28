# Copyright 2021 João Guerra
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

# https://github.com/bazelbuild/stardoc/
def io_bazel_stardoc():
    IO_BAZEL_STARDOC_TAG = "0.4.0"
    IO_BAZEL_STARDOC_SHA = "36b8d6c2260068b9ff82faea2f7add164bf3436eac9ba3ec14809f335346d66a"

    maybe(
        http_archive,
        name = "io_bazel_stardoc",
        sha256 = IO_BAZEL_STARDOC_SHA,
        strip_prefix = "stardoc-{}".format(IO_BAZEL_STARDOC_TAG),
        url = "https://github.com/bazelbuild/stardoc/archive/{}.zip".format(IO_BAZEL_STARDOC_TAG),
    )

# https://github.com/bazelbuild/rules_jvm_external/
def rules_jvm_external():
    RULES_JVM_EXTERNAL_TAG = "4.0"
    RULES_JVM_EXTERNAL_SHA = "31701ad93dbfe544d597dbe62c9a1fdd76d81d8a9150c2bf1ecf928ecdf97169"

    maybe(
        http_archive,
        name = "rules_jvm_external",
        sha256 = RULES_JVM_EXTERNAL_SHA,
        strip_prefix = "rules_jvm_external-{}".format(RULES_JVM_EXTERNAL_TAG),
        url = "https://github.com/bazelbuild/rules_jvm_external/archive/{}.zip".format(RULES_JVM_EXTERNAL_TAG),
    )
