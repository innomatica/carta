# Carta

Audiobook app for LibriVox and Internet Archive.


# How to build

Check [this page for Android](https://docs.flutter.dev/deployment/android) and
[this page for iOS](https://docs.flutter.dev/deployment/ios).

Note that the source is expecting `/android/key.properties` file for Android build.
Otherwise you need to delete keystore information from `/android/app/build.gradle`.

In other words, delete following lines from the build.gradle.
```
   def keystoreProperties = new Properties()
   def keystorePropertiesFile = rootProject.file('key.properties')
   if (keystorePropertiesFile.exists()) {
       keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
   }
```
And replace these lines
```
   signingConfigs {
       release {
           keyAlias keystoreProperties['keyAlias']
           keyPassword keystoreProperties['keyPassword']
           storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
           storePassword keystoreProperties['storePassword']
       }
   }
   buildTypes {
       release {
           signingConfig signingConfigs.release
       }
   }
```
with the lines below
```
   buildTypes {
       release {
           // TODO: Add your own signing config for the release build.
           // Signing with the debug keys for now,
           // so `flutter run --release` works.
           signingConfig signingConfigs.debug
       }
   }
```

[Check this for details.](https://docs.flutter.dev/deployment/android#create-an-upload-keystore).

# [Documentation](./extra/docs/index.md)


# TODO

- 
