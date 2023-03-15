// Top-level build file where you can add configuration options common to all sub-projects/modules.
plugins {
    id("org.jetbrains.kotlin.android") version "1.7.20" apply false
    id("org.jetbrains.dokka") version "1.7.20"
}

buildscript {
    val kotlinVersion: String by project
    repositories {
        mavenLocal()
        google()
    }
    dependencies {
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
        classpath("com.android.tools.build:gradle:7.4.2")
        classpath("org.eclipse.keyple:keyple-gradle:0.2.17")
    }
}
