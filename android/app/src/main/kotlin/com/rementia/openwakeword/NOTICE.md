The `com.rementia.openwakeword.lib` package in this directory is vendored
(copied, not linked) from [Re-MENTIA/openwakeword-android-kt](https://github.com/Re-MENTIA/openwakeword-android-kt),
licensed under the Apache License 2.0 (see `LICENSE` in this directory).
It itself uses the melspectrogram/embedding models from the
[openWakeWord](https://github.com/dscripka/openWakeWord) project by
David Scripka, also Apache 2.0.

Vendored (rather than pulled in as a Gradle dependency) because the
upstream project isn't published to a public Maven repository yet --
its own instructions are to `./gradlew publishToMavenLocal` from a
separate clone, which isn't something a CI build here should depend on.

No modifications were made to the copied source.
