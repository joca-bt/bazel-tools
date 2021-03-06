def _paths(depset):
    return [element.path for element in depset.to_list()]

def _javadoc_impl(ctx):
    srcs = depset(transitive = [depset(lib[JavaInfo].source_jars) for lib in ctx.attr.libs])
    deps = depset(transitive = [lib[JavaInfo].transitive_deps for lib in ctx.attr.libs])
    jar = ctx.actions.declare_file("{}.jar".format(ctx.label.name))

    java_home = ctx.attr._jdk[java_common.JavaRuntimeInfo].java_home
    tmp_dir = "{}.tmp/".format(jar.path)
    src_dir = "{}/src/".format(tmp_dir)
    javadoc_dir = "{}/javadoc/".format(tmp_dir)

    javadoc = [
        "{}/bin/javadoc".format(java_home),
        "-quiet",
        "-Xdoclint:all,-missing",
        "--class-path {}".format(":".join(_paths(deps))),
        "--source-path {}".format(src_dir),
        "-subpackages {}".format(":".join(ctx.attr.packages)),
        "-d {}".format(javadoc_dir),
        "-encoding UTF-8",
        "-notimestamp",
    ]

    for link in ctx.attr.links:
        javadoc.append("-link {}".format(link))

    if ctx.attr.title:
        javadoc.append("-doctitle '{}'".format(ctx.attr.title))
        javadoc.append("-windowtitle '{}'".format(ctx.attr.title))

    cmds = [
        "rm -rf {}".format(tmp_dir),
        "mkdir {}".format(tmp_dir),
        "unzip -q -d {} {}".format(src_dir, " ".join(_paths(srcs))),
        "rm -rf {}/META-INF/".format(src_dir),
        " ".join(javadoc),
        "{}/bin/jar -c -f {} -C {} .".format(java_home, jar.path, javadoc_dir),
    ]

    ctx.actions.run_shell(
        command = " && ".join(cmds),
        inputs = ctx.files._jdk + srcs.to_list() + deps.to_list(),
        outputs = [jar],
    )

    return DefaultInfo(files = depset([jar]))

javadoc = rule(
    doc = "Generate the Javadoc for a set of libraries.",
    implementation = _javadoc_impl,
    attrs = {
        "libs": attr.label_list(
            allow_empty = False,
            mandatory = True,
            providers = [JavaInfo],
        ),
        "links": attr.string_list(
            default = ["https://docs.oracle.com/en/java/javase/11/docs/api/"],
        ),
        "packages": attr.string_list(
            allow_empty = False,
            mandatory = True,
        ),
        "title": attr.string(),
        "_jdk": attr.label(
            default = Label("@bazel_tools//tools/jdk:current_host_java_runtime"),
            providers = [java_common.JavaRuntimeInfo],
        ),
    },
)
