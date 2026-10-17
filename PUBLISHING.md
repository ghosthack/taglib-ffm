# Publishing to Maven Central

Publishing is gated by a non-prerelease GitHub Release. Pushes and pull
requests only build and test.

## Release procedure

1. Replace the SNAPSHOT version in all three poms with one release version,
   update versioned documentation, and keep the SCM tag as `v${project.version}`.
2. Merge the release commit to `main` and wait for CI.
3. Publish a GitHub Release tagged `v<version>` at that exact commit.
4. The release workflow validates the tag, rebuilds/tests all three native
   platforms, and deploys the resulting classifier jars and Java artifact.

Configure `MAVEN_CENTRAL_USERNAME`, `MAVEN_CENTRAL_PASSWORD`,
`GPG_PRIVATE_KEY`, and `GPG_PASSPHRASE` as repository secrets.

Builds use the Maven Wrapper (`./mvnw`), which pins Maven 3.9.16. Do not
switch the release to the runner's `mvn`: under Maven 3.10 the
central-publishing plugin (0.11.0) stages resolver files such as
`_remote.repositories` and `maven-metadata-local.xml` into the bundle, and
Central rejects it with "Bundle has content that does NOT have a .pom file".

`./mvnw -Prelease -Dgpg.skip=true clean verify` checks sources, javadocs, and
packaging locally without publishing. Published Maven releases are immutable;
publish any correction under a new version.

To inspect the signed bundle CI would upload, run the Release workflow
manually (optionally with a throwaway `version`). It builds all three native
platforms, bundles against unreachable Central URLs with placeholder
credentials, fails if resolver files are in the bundle, and attaches
`central-bundle.zip` as a workflow artifact; nothing is published.
