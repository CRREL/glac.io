Deploying glacierresearch.org
=============================

To deploy a new version of **glacierresearch.org**, push to the **gh-pages** branch of the bare git repository at `lidar.io:/home/pgadomski/glacierresearch.org.git`.
Any pushes will automatically update the files in Apache's DocumentRoot via the use of a [post-receive hook](https://www.kernel.org/pub/software/scm/git/docs/githooks.html#post-receive).

For now, only @gadomski can update the site, since this repository is in his home directory.
If other folks want to update the site as well, we can move the bare git repository out of his home directory into some many-user accessible location.
