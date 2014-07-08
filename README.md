glac.io
=======

Static file website for visualizing glacier data.
Uses [wintersmith](http://wintersmith.io/) to generate content, and [d3.js](http://d3js.org/) for visualization.

This website can be viewed at at [http://gadomski.github.io/glac.io/](http://gadomski.github.io/glac.io/).
This *will* be changes in the near future to a (as of yet unspecified) custom domain.


Downloading and Viewing a Local Copy
------------------------------------

You can download the source code of this website and build your own copy, either for your own use or development purposes.

### System Dependencies

To download and view your own copy of this website, you need the following tools:

- [git](http://git-scm.com/)
- [node](http://nodejs.org/)

If you are using a Macintosh, [homebrew](http://brew.sh/) is a lovely little package manager that can handle these and other installs for you in a snap.
Installation instructions for **homebrew** are [here](http://brew.sh/#install).
Once you have **homebrew**, install **git** and **node**:

```bash
$ brew update
$ brew install git
$ brew install node
```

If you do not want to use **homebrew** or are not on a Macintosh, you're on your own.


### Website Dependencies

Once you've got **git** and **node**, clone the source code and install the website's dependencies:

```bash
# note: if you plan on making changes and pushing them back to Github, use git@github.com:gadomski/glac.io.git instead
$ git clone https://github.com/gadomski/glac.io.git  
$ cd glac.io
$ npm install
$ npm install -g wintersmith
```

[Node Package Manager](https://www.npmjs.org/) will install all external dependencies for the website.
Packages are installed locally for this repository, with the exception of **wintersmith**, which is installed globally so that you can access the **wintersmith** executable from the command line.


### Preview/Build

Once dependencies have been installed, you can preview the website with:

```bash
$ wintersmith preview
```

This will start a server on your localhost port 8888, by default.
To customize the port, use the -p option, e.g.:

```bash
$ wintersmith preview -p 5678
```

To build the site onto your local filesystem, run:

```bash
$ wintersmith build
```

This will process all of the source files and build the website directory tree inside the `build/` directory in your main **glac.io** repository.
To view the site in your local browser, you'll need a simple http server &mdash; **node** has one.
To install the http-server and view your website:

```bash
$ npm install -g http-server
$ cd build/
$ http-server
```

The **http-server** will give you a url, which you can then use to view your website in a browser.


Contributing
------------

We use Github's [issues and pull requests](https://github.com/gadomski/glac.io/issues?state=open) for all contributions.

This project is developed and maintained by:

- [@adamlewinter](https://github.com/adamlewinter)
- [@dcfinnegan](https://github.com/dcfinnegan)
- [@gadomski](https://github.com/gadomski)
