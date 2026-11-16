# Stable release procedure

1. Update `pubspec.yaml`, changelog, examples and documentation. Installation
   examples should name the upcoming version; avoid hardcoded publication claims
   before the artifact exists.
2. Push the reviewed commit to `main` and inspect CI: minimum/stable Dart,
   extension consumer, exact hosted consumer, Flutter tests/web build and dry-run.
3. Create `vMAJOR.MINOR.PATCH` at that commit. The publishing workflow first
   rejects non-stable tags and any tag that differs from the pubspec version.
   It then runs the full reusable CI before the Dart-maintained OIDC publisher.
4. Inspect the complete publishing workflow result and verify the new version
   and `kleberandrade.dev` publisher on pub.dev. Only then mark it published.
5. Advance the hosted consumer's exact version/expectation to the new artifact
   and push that verification commit. Inspect both hosted SDK jobs.

Pub.dev is configured for `kleberandrade/neural-engine`, tag pattern
`v{{version}}`, push events. No personal Pub token belongs in source or secrets.
The repository workflow uses the stable tag glob `v[0-9]*.[0-9]*.[0-9]*` plus an
exact regex/version guard, because a glob alone does not enforce semantic versions.
Publication cannot overwrite an existing version; fixes need a new version.
Prereleases need a deliberate workflow change rather than passing this stable guard.

A new tag reruns all checks even if the main-branch workflow already passed.
After a failed publication, inspect the stage and actual pub.dev availability
before retrying. Do not move a tag that already identifies a published artifact.
