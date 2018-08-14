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

Go to https://github.com/cybozu-go/neco-ubuntu/releases and edit the tag.
Finally, press `Publish release` button.

[example]: https://github.com/cybozu-go/etcdpasswd/commit/77d95384ac6c97e7f48281eaf23cb94f68867f79
