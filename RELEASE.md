Release procedure
=================

This document describes how to release a new version of neco-ubuntu.

Versioning
----------

Follow YYYYMMDD.

Prepare change log entries
--------------------------

Add notable changes since the last release to [CHANGELOG.md](CHANGELOG.md).
It should look like:

```markdown
(snip)
## [Unreleased]

### Added
- Implement ... (#35)

### Changed
- Fix a bug in ... (#33)

### Removed
- Deprecated `-option` is removed ... (#39)

(snip)
```

Bump version
------------

1. Determine a new version number.  Let it write `$VERSION`.
2. Checkout `master` branch.
3. Edit `CHANGELOG.md` for the new version ([example][]).
4. Commit the change and add a git tag, then push them.

    ```console
    $ VERSION=$(date +"%Y%m%d")
    $ git commit -a -m "Bump version to $VERSION"
    $ git tag $VERSION
    $ git push origin master --tags
    ```

Publish GitHub release page
---------------------------

Once a new tag is pushed to GitHub, [CircleCI](https://circleci.com/gh/cybozu/neco-ubuntu) automatically
builds custom images, and uploads it to GitHub releases page.

Visit https://github.com/cybozu/neco-ubuntu/releases to check
the result.  You may manually edit the page to describe the release.

[example]: https://github.com/cybozu-go/etcdpasswd/commit/77d95384ac6c97e7f48281eaf23cb94f68867f79
