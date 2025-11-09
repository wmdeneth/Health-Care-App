plugins {
    // Add Google Services Gradle plugin so it can be applied in module build files
    id("com.google.gms.google-services") version "4.4.4" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
