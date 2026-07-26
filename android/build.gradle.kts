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
// and automatically patch legacy proguard-android.txt references.
subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.gradle.LibraryExtension> {
            compileSdk = 36
        }
    }

    // Auto-patch cached third-party plugin build.gradle files (e.g., fllama)
    val pluginBuildFile = project.buildFile
    if (pluginBuildFile.exists()) {
        try {
            val content = pluginBuildFile.readText()
            if (content.contains("proguard-android.txt")) {
                val updatedContent = content.replace("proguard-android.txt", "proguard-android-optimize.txt")
                pluginBuildFile.writeText(updatedContent)
            }
        } catch (_: Exception) {}
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
