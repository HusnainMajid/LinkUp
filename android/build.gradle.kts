// Global properties for plugins to use
allprojects {
    extra.set("compileSdkVersion", 36)
    extra.set("targetSdkVersion", 36)
    extra.set("minSdkVersion", 24) // Required by app_links
}

subprojects {
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.library") || project.plugins.hasPlugin("com.android.application")) {
            extensions.configure<com.android.build.gradle.BaseExtension>("android") {
                compileSdkVersion(36)
                defaultConfig {
                    minSdk = 24
                    targetSdk = 36
                }
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_21
                    targetCompatibility = JavaVersion.VERSION_21
                }
            }
            
            project.tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                compilerOptions {
                    jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_21)
                }
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
