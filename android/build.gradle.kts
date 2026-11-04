allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    if (project.name != "app") {
        val setSdk = {
            val android = project.extensions.findByName("android")
            if (android != null) {
                try {
                    val compileSdkSetter = android.javaClass.methods.firstOrNull {
                        it.name == "setCompileSdk" && it.parameterCount == 1
                    }
                    compileSdkSetter?.invoke(android, 36)
                } catch (_: Throwable) {}
                try {
                    val compileSdkVersionMethod = android.javaClass.methods.firstOrNull {
                        it.name == "compileSdkVersion" && it.parameterCount == 1 && it.parameterTypes[0] == Int::class.javaPrimitiveType
                    }
                    compileSdkVersionMethod?.invoke(android, 36)
                } catch (_: Throwable) {}
            }
        }
        if (project.state.executed) {
            setSdk()
        } else {
            project.afterEvaluate {
                setSdk()
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
