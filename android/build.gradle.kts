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
    project.evaluationDependsOn(":app")
}

// Force all Flutter plugin subprojects to compile against SDK 36
// and automatically patch legacy proguard-android.txt, cmake, and kotlin version references.
subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.gradle.LibraryExtension> {
            compileSdk = 36
        }
    }

    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        incremental = false
    }

    // Auto-patch cached third-party plugin build.gradle files (e.g., fllama)
    val pluginBuildFile = project.buildFile
    if (pluginBuildFile.exists()) {
        try {
            var content = pluginBuildFile.readText()
            var modified = false
            if (content.contains("proguard-android.txt")) {
                content = content.replace("proguard-android.txt", "proguard-android-optimize.txt")
                modified = true
            }
            if (content.contains("version \"3.31.0\"")) {
                content = content.replace("version \"3.31.0\"", "version \"3.22.1\"")
                modified = true
            }
            if (content.contains("ext.kotlin_version = \"2.0.21\"")) {
                content = content.replace("ext.kotlin_version = \"2.0.21\"", "ext.kotlin_version = \"1.9.24\"")
                content = content.replace("apiVersion = \"2.1\"", "apiVersion = \"1.9\"")
                content = content.replace("languageVersion = \"2.1\"", "languageVersion = \"1.9\"")
                modified = true
            }
            if (modified) {
                pluginBuildFile.writeText(content)
            }
        } catch (_: Exception) {}
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
