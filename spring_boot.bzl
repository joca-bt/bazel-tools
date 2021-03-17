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

"""
Collection of Spring Boot rules:
  - spring_boot_binary, create an executable jar for a set of libraries (java_library).
"""

def _dependencies(ctx):
    deps = []

    for lib in ctx.attr.libs + ctx.attr.runtime_deps + [ctx.attr._jarmode_layertools]:
        deps.extend(lib[JavaInfo].transitive_runtime_deps.to_list())

    for lib in ctx.attr.libs:
        for src in lib[JavaInfo].runtime_output_jars:
            deps.remove(src)

    return depset(deps)

def _layers():
    return """\
- "dependencies":
  - "BOOT-INF/lib/"
- "spring-boot-loader":
  - "org/"
- "application":
  - "BOOT-INF/classes/"
  - "BOOT-INF/layers.idx"
  - "META-INF/"\
"""

def _manifest(ctx):
    return """\
Main-Class: {}
Start-Class: {}\
""".format(
        ctx.attr._loader_class,
        ctx.attr.main_class
    )

def _paths(depset):
    return [element.path for element in depset.to_list()]

def _spring_boot_binary_impl(ctx):
    srcs = depset(transitive = [depset(lib[JavaInfo].runtime_output_jars) for lib in ctx.attr.libs])
    deps = depset(transitive = [_dependencies(ctx)])
    loader = ctx.attr._loader[JavaInfo].runtime_output_jars[0]
    jar = ctx.outputs.jar

    java_home = ctx.attr._jdk[java_common.JavaRuntimeInfo].java_home
    tmp_dir = "{}.tmp/".format(jar.path)
    boot_inf_dir = "{}/BOOT-INF/".format(tmp_dir)
    classes_dir = "{}/classes/".format(boot_inf_dir)
    lib_dir = "{}/lib/".format(boot_inf_dir)

    cmds = [
        "rm -rf {}".format(tmp_dir),
        "mkdir {} {} {}".format(tmp_dir, boot_inf_dir, lib_dir),
        "unzip -q -d {} {}".format(classes_dir, " ".join(_paths(srcs))),
        "rm -rf {}/META-INF/".format(classes_dir),
        "echo '{}' > {}/layers.idx".format(_layers(), boot_inf_dir),
        "unzip -q -d {} {}".format(tmp_dir, loader.path),
        "rm -f {}/META-INF/*".format(tmp_dir),
        "echo '{}' > {}/META-INF/MANIFEST.MF".format(_manifest(ctx), tmp_dir),
        "{0}/bin/jar -c -f {1} -m {2}/META-INF/MANIFEST.MF -C {2} .".format(java_home, jar.path, tmp_dir),
        "cp {} {}".format(" ".join(_paths(deps)), lib_dir),
        "{}/bin/jar -u -0 -f {} -C {} BOOT-INF/lib/".format(java_home, jar.path, tmp_dir),
    ]

    ctx.actions.run_shell(
        command = " && ".join(cmds),
        inputs = ctx.files._jdk + srcs.to_list() + deps.to_list() + [loader],
        outputs = [jar],
    )

spring_boot_binary = rule(
    implementation = _spring_boot_binary_impl,
    attrs = {
        "libs": attr.label_list(
            allow_empty = False,
            mandatory = True,
        ),
        "main_class": attr.string(
            mandatory = True,
        ),
        "runtime_deps": attr.label_list(),
        "_jarmode_layertools": attr.label(
            default = Label("@maven//:org_springframework_boot_spring_boot_jarmode_layertools"),
        ),
        "_jdk": attr.label(
            default = Label("@bazel_tools//tools/jdk:current_host_java_runtime"),
            providers = [java_common.JavaRuntimeInfo],
        ),
        "_loader": attr.label(
            default = Label("@maven//:org_springframework_boot_spring_boot_loader"),
        ),
        "_loader_class": attr.string(
            default = "org.springframework.boot.loader.JarLauncher",
        ),
    },
    outputs = {
        "jar": "%{name}.jar",
    },
)
