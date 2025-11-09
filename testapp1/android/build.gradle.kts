allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    // Set a common build directory for subprojects only when the subproject
    // is inside the root project directory. This avoids mixing build dirs
    // across different drive roots (e.g., when plugins live in the Pub
    // cache on a different drive) which causes Gradle to throw
    // "this and base files have different roots" errors on Windows.
    try {
        val rootPath = rootProject.projectDir.absolutePath
        val projPath = project.projectDir.absolutePath
        if (projPath.startsWith(rootPath)) {
            val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
            project.layout.buildDirectory.value(newSubprojectBuildDir)
        }
    } catch (e: Exception) {
        // If anything goes wrong, don't override the subproject buildDir.
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
