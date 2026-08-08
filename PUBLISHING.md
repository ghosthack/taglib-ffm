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

`mvn -Prelease -Dgpg.skip=true clean verify` checks sources, javadocs, and
packaging locally without publishing. Published Maven releases are immutable;
publish any correction under a new version.
