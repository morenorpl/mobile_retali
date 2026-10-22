// android/build.gradle.kts (Top-level)

val kotlinVersion = "1.9.24" // versi Kotlin project

// android/build.gradle.kts (Top-level untuk proyek Flutter/Android)

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Android Gradle Plugin (samakan dengan versi wrapper kamu)
        classpath("com.android.tools.build:gradle:8.2.2")
        // Kotlin Gradle Plugin — pakai versi langsung, tanpa variabel
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.24")
        // Google Services (Firebase, dsb)
        classpath("com.google.gms:google-services:4.4.2")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Opsional (gaya proyek Flutter): arahkan output build ke ../../build
val newBuildDir = rootProject.layout.buildDirectory
    .dir("../../build")
    .get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    layout.buildDirectory.set(newSubprojectBuildDir)
    evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
