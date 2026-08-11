allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    // Global properties for plugins to use
    extra.set("compileSdkVersion", 36)
    extra.set("targetSdkVersion", 36)
    extra.set("minSdkVersion", 24) // Required by app_links
}

// Force all plugins to use the same SDK version
subprojects {
    project.plugins.withType<com.android.build.gradle.BasePlugin>().configureEach {
        project.extensions.configure<com.android.build.gradle.BaseExtension>("android") {
            compileSdkVersion(36)
            defaultConfig {
                minSdk = 24
                targetSdk = 36
            }
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
